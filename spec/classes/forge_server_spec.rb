require 'spec_helper'
describe 'forge_server' do
  on_supported_os.each do |os, facts|
    context "with defaults for all parameters (on #{os})" do
      let(:facts) do
        facts
      end

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_package('puppet-forge-server') }
      it { is_expected.not_to contain_exec('scl_install_forge_server') }
      it { is_expected.not_to contain_file('/etc/init.d/puppet-forge-server').with_content(%r{export LD_LIBRARY_PATH=.*\nexport GEM_PATH=.*\nexport PATH=.*\n}) }
    end
    context "with single module path and proxy (on #{os})" do
      let(:params) do
        {
          module_directory: '/dir1',
          proxy: 'proxy1'
        }
      end
      let(:facts) do
        facts
      end

      it { is_expected.to compile.with_all_deps }

      case facts[:osfamily]
      when 'RedHat'
        it { is_expected.to contain_file('/etc/default/puppet-forge-server').with_content(%r{PARAMS=\"${PARAMS} --module-dir /dir1\"}) }
        it { is_expected.to contain_file('/etc/default/puppet-forge-server').with_content(%r{PARAMS=\"${PARAMS} --proxy proxy1\"}) }
      when 'Debian'
        it { is_expected.to contain_file('/etc/default/puppet-forge-server').with_content(%r{PARAMS="\${PARAMS} --module-dir /dir1"}) }
        it { is_expected.to contain_file('/etc/default/puppet-forge-server').with_content(%r{PARAMS="\${PARAMS} --proxy proxy1"}) }
      end
    end

    context "with multiple module paths and proxies (on #{os})" do
      let(:params) do
        {
          module_directory: ['/dir1', '/dir2'],
          proxy: ['proxy1', 'proxy2']
        }
      end
      let(:facts) do
        facts
      end

      it { is_expected.to compile.with_all_deps }

      case facts[:osfamily]
      when 'RedHat'
        it {
          is_expected.to contain_file('/etc/default/puppet-forge-server')
            .with_content(%r{PARAMS="\${PARAMS} --module-dir \\"/dir1\\""\nPARAMS="\${PARAMS} --module-dir \\"/dir2\\""\n})
            .with_content(%r{PARAMS="\${PARAMS} --proxy proxy1"\nPARAMS="\${PARAMS} --proxy proxy2"\n})
        }
      when 'Debian'
        it {
          is_expected.to contain_file('/etc/default/puppet-forge-server')
            .with_content(%r{PARAMS="\${PARAMS} --module-dir /dir1"\nPARAMS="\${PARAMS} --module-dir /dir2"\n})
            .with_content(%r{PARAMS="\${PARAMS} --proxy proxy1"\nPARAMS="\${PARAMS} --proxy proxy2"\n})
        }
      end
    end

    context "with service_refresh => false (on #{os})" do
      let(:params) do
        {
          service_refresh: false
        }
      end
      let(:facts) do
        facts
      end

      it { is_expected.to compile.with_all_deps }
      it { is_expected.not_to contain_class('::forge_server::package').that_notifies('Class[::forge_server::service]') }
      it { is_expected.not_to contain_class('::forge_server::config').that_notifies('Class[::forge_server::service]') }
    end

    context "with scl => ruby193 (on #{os})" do
      let(:params) do
        {
          scl: 'ruby193'
        }
      end
      let(:facts) do
        facts
      end

      case facts[:osfamily]
      when 'RedHat'
        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to contain_package('puppet-forge-server') }
        it { is_expected.to contain_exec('scl_install_forge_server').with(command: "scl enable ruby193 'gem install --bindir /usr/bin --no-rdoc --no-ri puppet-forge-server'") }
        if facts[:release] == 6
          it { is_expected.to contain_file('/etc/init.d/puppet-forge-server').with_content(%r{export LD_LIBRARY_PATH=.*\nexport GEM_PATH=.*\nexport PATH=.*\n}) }
        end
      else
        it { is_expected.not_to compile }
      end
    end

    # rubocop:disable EmptyExampleGroup
    context "with scl, scl_install_timeout and scl_install_retries (on #{os})" do
      let(:params) do
        {
          scl: 'ruby193',
          scl_install_timeout: 60_000,
          scl_install_retries: 10
        }
      end
      let(:facts) do
        facts
      end

      case facts[:osfamily]
      when 'RedHat'
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_exec('scl_install_forge_server').with_timeout(60_000).with_tries(10) }
      else
        it { is_expected.not_to compile }
      end
    end
    # rubocop:enable EmptyExampleGroup
  end
end
