ActiveRecord::Schema.define(:version => 20090317164830) do
  create_table "androids", :force => true do |t|
    t.string   "name"
    t.integer  "owner_id"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "people", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "components", :force => true do |t|
    t.string   "name"
    t.integer  "android_id"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sub_components", :force => true do |t|
    t.string "name"
    t.integer "component_id"
    t.datetime "deleted_at"
  end

  create_table "memories", :force => true do |t|
    t.string   "name"
    t.integer  "parent_id"
    t.datetime "deleted_at"
  end

  create_table "stickers", :force => true do |t|
    t.string   "name"
    t.integer  "android_id"
    t.datetime "deleted_at"
  end

  create_table "ninjas", :force => true do |t|
    t.string   "name"
    t.boolean  "visible", :default => false
  end

  create_table "pirates", :force => true do |t|
    t.string   "name"
    t.boolean  "alive", :default => true
  end

  create_table "companies", :force => true do |t|
    t.string   "name"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "contacts", :force => true do |t|
    t.string   "firstname"
    t.string   "lastname"
    t.integer "company_id"
    t.string "type"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "addresses", :force => true do |t|
    t.string   "street"
    t.string   "city"
    t.integer   "zipcode"
    t.integer "contact_id"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "projects", :force => true do |t|
    t.string   "name"
    t.integer "company_id"
    t.integer "manager_id"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end
end
