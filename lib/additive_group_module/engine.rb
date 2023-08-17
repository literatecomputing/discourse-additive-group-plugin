# frozen_string_literal: true

module ::AdditiveGroupModule
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace AdditiveGroupModule
    config.autoload_paths << File.join(config.root, "lib")
  end
  def self.add_user_to_groups(user, groups)
    groups.each do |group|
      next if user.groups.include?(group)
      GroupUser.create!(user_id: user.id, group_id: group.id)
      GroupActionLogger.new(Discourse.system_user, group).log_add_user_to_group(user)
    end
  end

  # https://github.com/discourse/discourse/blob/main/app/models/discourse_connect.rb#L443-L#448
  def self.remove_user_from_groups(user, groups)
    GroupUser.where(user_id: user.id, group_id: groups.map(&:id)).destroy_all
    groups.each do |group|
      GroupActionLogger.new(Discourse.system_user, group).log_remove_user_from_group(user)
    end
  end

  def self.add_if_member(user, group_memberships, add_to_group)
    if group_memberships.pluck(:name).intersection(user.groups.pluck(:name)).count ==
         group_memberships.count
      add_user_to_groups(user, [add_to_group])
    end
  end

  def self.delete_unless_member(user, required_memberships, remove_from_group)
    unless required_memberships.pluck(:name).intersection(user.groups.pluck(:name)).count ==
             required_memberships.count
      remove_user_from_groups(user, [remove_from_group])
    end
  end
end
