# frozen_string_literal: true

# name: discourse-additive-group-plugin
# about: TODO
# version: 0.0.1
# authors: Discourse
# url: TODO
# required_version: 2.7.0

enabled_site_setting :additive_groups_enabled

module ::AdditiveGroupModule
  PLUGIN_NAME = "discourse-additive-group-plugin"
end

require_relative "lib/additive_group_module/engine"

after_initialize do
  # Code which should run after Rails has finished booting
  add_model_callback(GroupUser, :after_save) do
    group_list = SiteSetting.additive_groups_list.split("|")
    user = User.find(self.user_id)
    group_list.each do |gl|
      required_group_names, add_group_name = gl.split(":")
      add_group = Group.find_by_name(add_group_name)
      next unless add_group
      required_groups=Group.where("name in ('#{required_group_names.gsub(",","','")}')")
      AdditiveGroupModule::add_if_member(user, required_groups, add_group )
    end
  end

  add_model_callback(GroupUser, :after_destroy) do
    group_list = SiteSetting.additive_groups_list.split("|")
    user = User.find(self.user_id)
    group_list.each do |gl|
      required_group_names, rm_group_name = gl.split(":")
      rm_group=Group.find_by_name(rm_group_name)
      next unless rm_group
      required_groups=Group.where("name in ('#{required_group_names.gsub(",","','")}')")
      AdditiveGroupModule::delete_unless_member(user, required_groups, rm_group )
    end
  end

  DiscourseEvent.on(:user_promoted) do |event|
    next unless event[:new_trust_level] < event[:old_trust_level]
    # increases in trust level do show up in the above after_save callback, but decreases do not
    group_list = SiteSetting.additive_groups_list.split("|")
    user = User.find(event[:user_id])
    group_list.each do |gl|
    required_group_names, rm_group_name = gl.split(":")
    rm_group=Group.find_by_name(rm_group_name)
    next unless rm_group
    required_groups=Group.where("name in ('#{required_group_names.gsub(",","','")}')")
    AdditiveGroupModule::delete_unless_member(user, required_groups, rm_group )
    end
  end
end
