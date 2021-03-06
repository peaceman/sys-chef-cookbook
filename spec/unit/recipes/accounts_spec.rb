require 'chefspec'
require 'chefspec/server'

describe 'sys::accounts' do
  let(:chef_run) { ChefSpec::Runner.new.converge(described_recipe) }

  context 'node.sys.accounts.message is empty' do
    it 'does nothing' do
      expect(chef_run.run_context.resource_collection).to be_empty
    end
  end

  context 'with some test attributes' do
    before do
      @g1 = { 'gid' => 1337 }
      @g2 = {}
      chef_run.node.default['sys']['groups']['g1'] = @g1
      chef_run.node.default['sys']['groups']['g2'] = @g2
      @u1 = {
        'uid'      => 666,
        'gid'      => 'fauxhai',
        'shell'    => '/bin/zsh',
        'home'     => '/home/u1',
        'password' => '$asdf',
        'system'   => true,
        'supports' => { 'manage_home' => true }
      }
      @u2 = { 'password' => 'asdf' }
      @u3 = { 'gid' => 0 } # the fauxhai group has gid 0
      @u4 = { 'gid' => 1337 }
      @u5 = { 'supports' => { 'manage_home' => true } }
      @u6 = { 'gid' => 'doesnotexist' }
      chef_run.node.default['sys']['accounts']['u1'] = @u1
      chef_run.node.default['sys']['accounts']['u2'] = @u2
      chef_run.node.default['sys']['accounts']['u3'] = @u3
      chef_run.node.default['sys']['accounts']['u4'] = @u4
      chef_run.node.default['sys']['accounts']['u5'] = @u5
      chef_run.node.default['sys']['accounts']['u6'] = @u6
      @u2item = {
        'id' => 'u2',
        'account' => {
          'home' => '/home/u2'
        }
      }
      @u4item = {
        'id' => 'u4',
        'account' => {
          'gid' => 'shouldnotbeseen',
          'home' => '/home/u4'
        }
      }
      ChefSpec::Server.create_data_bag('accounts', {
        'u2' => @u2item,
        'u4' => @u4item
      })
      chef_run.converge(described_recipe)
    end

    it 'installs package ruby-shadow' do
      expect(chef_run).to install_package('ruby-shadow')
    end

    it 'manages groups' do
      expect(chef_run).to create_group('g1').with_gid(1337)
      expect(chef_run).to create_group('g2')
    end

    it 'manages users' do
      expect(chef_run).to create_user('u1').with({
        :uid => @u1['uid'],
        :gid => @u1['gid'],
        :home => @u1['home'],
        :shell => @u1['shell'],
        :password => @u1['password'],
        :comment => @u1['comment'],
        :supports => @u1['supports'],
        :system => @u1['system']
      })
      expect(chef_run).to create_user('u2')
      expect(chef_run).to create_user('u3')
      expect(chef_run).to create_user('u4')
      expect(chef_run).to create_user('u5')
      expect(chef_run).to_not create_user('u6')
    end

    it 'adds and honors manage_home flag' do
      expect(chef_run).to create_user('u5').with_supports(@u5['supports'])
      expect(chef_run).to create_user('u2').with_supports({ 'manage_home' => true })
    end

    it 'merges attributes with data bag item' do
      expect(chef_run).to create_user('u4').with_home(@u4item['account']['home']).with_gid(@u4['gid'])
    end
  end
end
