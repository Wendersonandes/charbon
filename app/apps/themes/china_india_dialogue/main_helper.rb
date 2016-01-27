module Themes::ChinaIndiaDialogue::MainHelper
  def self.included(klass)
    # klass.helper_method [:my_helper_method] rescue "" # here your methods accessible from views
    klass.helper_method [:theme_image_tag, :nav_menu]
  end

  def china_india_dialogue_settings(theme)
    # here your code on save settings for current site, by default params[:theme_fields] is auto saved into theme
    # Also, you can save your extra values added in admin/settings.html.erb
    # sample: theme.set_meta("my_key", params[:my_value])
    #theme.set_field_values(params[:field_options])
  end

  # callback called after theme installed
  def china_india_dialogue_on_install_theme(theme)
    #unless theme.get_field_groups.where(slug: "fields").any?
      # group = theme.add_field_group({name: "Main Settings", slug: "fields", description: ""})
      # group.add_field({"name"=>"Background color", "slug"=>"bg_color"},{field_key: "colorpicker"})
      # group.add_field({"name"=>"Links color", "slug"=>"links_color"},{field_key: "colorpicker"})
      # group.add_field({"name"=>"Background image", "slug"=>"bg"},{field_key: "image"})
    #end
   
   unless theme.get_field_groups.where(slug: "footer").any?   
      group = theme.add_field_group({name: "Footer", slug: "footer"})
      group.add_field({"name"=>"Address", "slug"=>"address"}, {field_key: "editor", translate: true, default_value: "<p><b>Address:</b><br/>33 Chegongzhuang Xilu,<br/>Beijing, 100048, P.R. China</p><p><b>Telephone:</b><br/>+8610 8888 8888</p><p><b>Email:</b> contact@mycompany.cn</p>"})
    end
    
    unless theme.get_field_groups.where(slug: "partners").any? 
      group = theme.add_field_group({name: "Partners", slug: "partners"})
      group.add_field({"name"=>"Partners", "slug"=>"partners"}, {field_key: "editor", translate: true, default_value: ""})
    end
    
    unless theme.get_field_groups.where(slug: "ads").any? 
      group = theme.add_field_group({name: "Ads", slug: "ads"})
      group.add_field({"name"=>"Left", "slug"=>"ad_left"}, {field_key: "editor", translate: true, default_value: ""})
      group.add_field({"name"=>"Right", "slug"=>"ad_right"}, {field_key: "editor", translate: true, default_value: ""})
    end
    
    theme.set_meta("installed_at", Time.current.to_s) # save a custom value
  end

  # callback executed after theme uninstalled
  def china_india_dialogue_on_uninstall_theme(theme)
  end
  
  def theme_image_tag(source, options={})
    ActionController::Base.helpers.image_tag(theme_asset_path("images/#{source}"), options)
  end
  
  def nav_menu(options={})
    options.merge!(callback_item: lambda{|args| args[:item_container_attrs] = "ui-sref-active='active'"; args[:link_attrs] = "ui-sref=\"category({categoryId: #{args[:menu_item][:id]}, categorySlug: '#{args[:menu_item][:slug]}'})\" href"})
    draw_menu(options).html_safe
  end
end
