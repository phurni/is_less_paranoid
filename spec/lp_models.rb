class Company < ActiveRecord::Base #:nodoc:
  is_less_paranoid
  has_many :contacts, :class_name => 'ContactAlive', :dependent => :destroy
end

class Contact < ActiveRecord::Base #:nodoc:
  is_less_paranoid
  
  def self.get_my_name
    name
  end
  
  has_many :addresses, :dependent => :destroy
  belongs_to :company
end

class VipContact < Contact
end

class Address < ActiveRecord::Base #:nodoc:
  is_less_paranoid :clone => :with_destroyed, :suffix => 'WithInvalid'
  belongs_to :contact
end

class Project < ActiveRecord::Base #:nodoc:
  belongs_to :company
  belongs_to :manager, :class_name => 'Contact'
end
