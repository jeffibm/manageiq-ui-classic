describe ChartsLayoutService do
  let(:host_openstack_infra) { FactoryBot.create(:host_openstack_infra) }
  let(:host_redhat) { FactoryBot.create(:host_redhat) }
  let(:vm_openstack) { FactoryBot.create(:vm_openstack) }
  let(:host_openstack_infra_chart) do
    YAML.load(File.read(File.join(ApplicationController::Performance::CHARTS_LAYOUTS_FOLDER, 'daily_perf_charts', 'ManageIQ_Providers_Openstack_InfraManager_Host') + '.yaml'))
  end
  let(:host_chart) do
    YAML.load(File.read(File.join(ApplicationController::Performance::CHARTS_LAYOUTS_FOLDER, 'daily_perf_charts', 'Host') + '.yaml'))
  end
  let(:layout_chart) do
    YAML.load(File.read(File.join(ApplicationController::Performance::CHARTS_LAYOUTS_FOLDER, 'daily_util_charts') + '.yaml'))
  end

  describe "#layout" do
    it "returns layout for specific class if exists" do
      chart = ChartsLayoutService.layout(host_openstack_infra, ApplicationController::Performance::CHARTS_LAYOUTS_FOLDER, 'daily_perf_charts', 'Host')
      expect(chart).to eq(host_openstack_infra_chart)
    end

    it "returns layout for fname if specific class does not exist" do
      allow(host_redhat).to receive(:cpu_percent_available?).and_return(true)
      allow(host_redhat).to receive(:cpu_mhz_available?).and_return(true)
      chart = ChartsLayoutService.layout(host_redhat, ApplicationController::Performance::CHARTS_LAYOUTS_FOLDER, 'daily_perf_charts', 'Host')
      expect(chart).to eq(host_chart)
    end

    it "returns base layout if fname is missing" do
      chart = ChartsLayoutService.layout(host_openstack_infra, ApplicationController::Performance::CHARTS_LAYOUTS_FOLDER, 'daily_util_charts')
      expect(chart).to eq(layout_chart)
    end
  end

  describe "#layout applies_to_method functionality" do
    it "shows CPU (Mhz) by default for Host" do
      chart = ChartsLayoutService.layout(host_redhat, ApplicationController::Performance::CHARTS_LAYOUTS_FOLDER, 'daily_perf_charts', 'Host')
      expect(chart.count { |x| x[:title] == "CPU (%)" }).to eq(0)
      expect(chart.count { |x| x[:title] == "CPU (Mhz)" }).to eq(1)
    end

    it "shows CPU (%) when a Host has cpu_percent_available" do
      allow(host_redhat).to receive(:cpu_percent_available?).and_return(true)
      allow(host_redhat).to receive(:cpu_mhz_available?).and_return(false)
      chart = ChartsLayoutService.layout(host_redhat, ApplicationController::Performance::CHARTS_LAYOUTS_FOLDER, 'daily_perf_charts', 'Host')
      expect(chart.count { |x| x[:title] == "CPU (%)" }).to eq(1)
      expect(chart.count { |x| x[:title] == "CPU (Mhz)" }).to eq(0)
    end

    it "shows CPU (%) by default for VmOpenstack" do
      # By default percent is visible and mhz not
      chart = ChartsLayoutService.layout(vm_openstack, ApplicationController::Performance::CHARTS_LAYOUTS_FOLDER, 'daily_perf_charts', 'VmOrTemplate')
      expect(chart.count { |x| x[:title] == "CPU (%)" }).to equal 1
      expect(chart.count { |x| x[:title] == "CPU (Mhz)" }).to equal 0
    end

    it "shows CPU (Mhz) instead of CPU (%), when applies_to_method methods are changed" do
      # Stub it so mhz is visible and percent not
      allow(vm_openstack).to receive(:cpu_percent_available?).and_return(false)
      allow(vm_openstack).to receive(:cpu_mhz_available?).and_return(true)
      chart = ChartsLayoutService.layout(vm_openstack, ApplicationController::Performance::CHARTS_LAYOUTS_FOLDER, 'daily_perf_charts', 'VmOrTemplate')
      expect(chart.count { |x| x[:title] == "CPU (%)" }).to equal 0
      expect(chart.count { |x| x[:title] == "CPU (Mhz)" }).to equal 1
    end

    it "includes Memory (MB) chart for azure instance" do
      ems_azure = FactoryBot.create(:ems_azure)
      host = FactoryBot.create(:host, :ext_management_system => ems_azure)
      vm_azure = FactoryBot.create(:vm_azure, :ext_management_system => ems_azure, :host => host)
      chart = ChartsLayoutService.layout(vm_azure, ApplicationController::Performance::CHARTS_LAYOUTS_FOLDER, 'daily_perf_charts', 'VmOrTemplate')
      expect(chart.count { |x| x[:title] == "Memory (MB)" }).to equal 1
    end
  end
end
