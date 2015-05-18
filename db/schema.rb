# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150503165406) do

  create_table "keywords", force: :cascade do |t|
    t.integer  "slideid",    limit: 4
    t.text     "word",       limit: 65535, null: false
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "keywords", ["word"], name: "keyword_fulltext_index", type: :fulltext

  create_table "slides", force: :cascade do |t|
    t.string   "title",      limit: 255
    t.string   "filename",   limit: 255
    t.string   "path",       limit: 255
    t.string   "user",       limit: 255
    t.string   "pass",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "slides", ["user"], name: "index_slides_on_user", using: :btree

  create_table "tags", force: :cascade do |t|
    t.string   "tagname",    limit: 255
    t.integer  "slideid",    limit: 4
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "tags", ["slideid"], name: "index_tags_on_slideid", using: :btree
  add_index "tags", ["tagname"], name: "index_tags_on_tagname", using: :btree

end
