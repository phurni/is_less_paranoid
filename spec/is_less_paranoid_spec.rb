require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/lp_models')

describe IsLessParanoid do
  before(:each) do
    Company.delete_all
    Contact.delete_all
    Address.delete_all
    Project.delete_all

    @world = Company.create(:name => 'World')
    @sly = @world.contacts.create(:firstname => 'Sly')
    @george = @world.contacts.create(:firstname => 'George')
    @big = Project.create(:company => @world, :manager => @sly)
  end

  describe 'clone class' do
    it "should have the table name of the original class" do
      CompanyAlive.table_name.should == 'companies'
    end
  
    it "should contain class methods of original class" do
      Contact.get_my_name.should == 'Contact'
      lambda {
        ContactAlive.get_my_name.should == 'ContactAlive'
      }.should_not raise_error(NoMethodError)
    end
  
    it "should store the original class name in STI type field" do
      VipContact.create(:firstname => 'Babushka')
      VipContactAlive.create(:firstname => 'Schwarzie')
      VipContact.all.all? {|contact| contact.type == 'VipContact'}.should be_true
    end
  
    it "should equals record from the original class" do
      Contact.first.should == ContactAlive.first
      ContactAlive.first.should == Contact.first
    end

    it "should not equals record from another class" do
      ContactAlive.first.should_not == Company.first
    end

    describe 'subclassing' do
      it "should not create a derivative clone class" do
        lambda {
          class VeryVipContact < VipContactAlive
          end
          VeryVipContactAlive
        }.should raise_error(NameError)
      end
    end
  end

  describe 'destroying' do
    it "should mark the record deleted" do
       lambda{
         Contact.destroy(@sly.id)
       }.should_not change(Contact, :count)
       Contact.count_with_destroyed.should == 2
    end

    it "should soft-delete a record" do
       lambda{
         ContactAlive.destroy(@sly.id)
       }.should change(ContactAlive, :count).from(2).to(1)
       Contact.count_with_destroyed.should == 2
    end

    it "should soft-delete matching items on Model.destroy_all" do
      lambda{
        ContactAlive.destroy_all("company_id = #{@world.id}")
      }.should change(ContactAlive, :count).from(2).to(0)
      ContactAlive.count_with_destroyed.should == 2
    end

    describe 'related models' do
      it "should still show up in the relationship to the owner" do
        @world.contacts.size.should == 2
        @george.destroy
        @world.contacts.size.should == 1
      end

      it "should soft-delete on dependent destroys" do
        lambda{
          @world.destroy
        }.should change(ContactAlive, :count).from(2).to(0)
        ContactAlive.count_with_destroyed.should == 2
      end
    
      it "should delete the alive association but preserve the normal one" do
        @world.contacts.first.destroy
        ContactAlive.count.should == 1
        Contact.count.should == 2
      end
    
    end
  end

  describe 'subclassing' do
    it "should create a clone class" do
      lambda {
        VipContactAlive
      }.should_not raise_error(NameError)
    end
  end

  describe 'finding destroyed models' do
    it "should be able to find destroyed items in the original class" do
      @sly.destroy
      Contact.find(:first, :conditions => {:firstname => 'Sly'}).should_not be_blank
    end

    it "should not be able to find destroyed items in the clone class" do
      @sly.destroy
      ContactAlive.find(:first, :conditions => {:firstname => 'Sly'}).should be_blank
      ContactAlive.first_with_destroyed(:conditions => {:firstname => 'Sly'}).should_not be_blank
    end

    it "should be able to find destroyed items in the clone class with find_with_destroyed" do
      @sly.destroy
      ContactAlive.first_with_destroyed(:conditions => {:firstname => 'Sly'}).should_not be_blank
    end

    it "should show destroyed models via :include" do
      Company.first(:conditions => {:name => 'World'}, :include => :contacts).contacts.size.should == 2
      @sly.destroy
      company = Company.first(:conditions => {:name => 'World'}, :include => :contacts)
      # ensure that we're using the preload and not loading it via a find
      Contact.should_not_receive(:find)
      company.contacts.size.should == 2
    end
  end

  describe 'calculations' do
    it "should have no count difference of destroyed items on the original class" do
      @sly.destroy
      @george.destroy
      Contact.count.should == 2
    end

    it "should have a proper count inclusively and exclusively of destroyed items on the clone class" do
      @sly.destroy
      @george.destroy
      ContactAlive.count.should == 0
      ContactAlive.count_with_destroyed.should == 2
    end
  end

  describe 'deletion on clone class' do
    it "should actually remove records on #delete_all" do
      lambda{
        ContactAlive.delete_all
      }.should change(ContactAlive, :count_with_destroyed).from(2).to(0)
    end

    it "should actually remove records on #delete" do
      lambda{
        ContactAlive.first.delete
      }.should change(ContactAlive, :count_with_destroyed).from(2).to(1)
    end
  end

end
