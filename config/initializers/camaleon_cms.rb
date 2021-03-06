CamaleonCms::UserDecorator.class_eval do
  
  def get_locale
    object.get_field('locale')
  end
end

CamaleonCms::AdminController.class_eval do

  def admin_init_actions
    I18n.locale = current_user.get_locale || current_site.get_admin_language
    @_admin_menus = {}
    @_admin_breadcrumb = []
    @_extra_models_for_fields = []
    @cama_i18n_frontend = current_site.get_languages.first
  end

end


CamaleonCms::SiteDecorator.class_eval do
  
  def draw_languages_text(list_class = "language_list list-inline pull-right", current_page = false, current_class = "current_l", link_class='text-white', hide_active=false)
    lan = object.get_languages
    return  if  lan.size < 2
    res = ["<ul class='#{list_class}'>"]
    lan.each do |lang|
      # if hide_active && I18n.locale.to_s.eql?(lang.to_s)
      # else
      #   res << "<li class='#{ current_class if I18n.locale.to_s == lang.to_s}'> <a href='#{h.cama_url_to_fixed(current_page ? "url_for" : "cama_root_url", {locale: lang, cama_set_language: lang})}' class='#{link_class}'>#{I18n.t(lang)}</a> </li>"
      # end
     res << "<li class='#{ current_class if I18n.locale.to_s == lang.to_s}'> <a href='#{h.cama_url_to_fixed("cama_root_url", {locale: lang, cama_set_language: lang})}' class='#{link_class}'>#{I18n.t(lang)}</a> </li>" 
    end
    res << "</ul>"
    res.join("")
  end
  
  def the_posts_cid(options={})
    
    excluded_cat_ids = []
    unless options[:cat_slugs].blank?
      excluded_cat_ids = options[:cat_slugs].collect{|_| CamaleonCms::Category.find_by_slug(_).try(:id)}.compact 
    end
    
    posts = object.posts.published
    .joins("LEFT OUTER JOIN cama_metas cm ON cm.objectid = cama_posts.id AND cm.object_class = 'Post' AND cm.key = 'enabled_languages'")
    .where("(#{CamaleonCms::Post.table_name}.published_at is not null and #{CamaleonCms::Post.table_name}.published_at <= ?)", Time.now)
    .where("visibility != 'private'")
    .where('cm.value is null or cm.value like ?', "%#{I18n.locale.to_s}%")
    .where("#{CamaleonCms::TermTaxonomy.table_name}.slug = ?", 'post')
    .reorder(published_at: :desc)
    
    unless excluded_cat_ids.blank?
      posts = posts
      .joins("INNER JOIN cama_term_relationships ctr ON ctr.objectid = #{CamaleonCms::Post.table_name}.id")
      .joins("INNER JOIN cama_term_taxonomy ctt ON ctt.id = ctr.term_taxonomy_id AND ctt.taxonomy = 'category'")
      .where('ctt.id not in (?)', excluded_cat_ids)
      .distinct
    end
    
    posts
  end
end

CamaleonCms::PostDecorator.class_eval do
  def the_thumb_url(default = nil)
    th = object.get_meta("thumb")
    begin
      th.present? ? th.gsub(' ','%20') : (default || object.post_type.get_option('default_thumb', nil) || h.asset_url("camaleon_cms/image-not-found.png"))
    rescue
      ""
    end
  end
  
  def the_related_posts_cid
    self.the_post_type.posts.published.joins(:categories)
    .joins("LEFT OUTER JOIN cama_metas cm ON cm.objectid = cama_posts.id AND cm.object_class = 'Post' AND cm.key = 'enabled_languages'")
    .where("(#{CamaleonCms::Post.table_name}.published_at is not null and #{CamaleonCms::Post.table_name}.published_at <= ?)", Time.now)
    .where("visibility != 'private'")
    .where('cm.value is null or cm.value like ?', "%#{I18n.locale.to_s}%")
    .where("#{CamaleonCms::TermRelationship.table_name}" => {term_taxonomy_id: the_categories.pluck(:id)})
    .where('cama_posts.id != ?', id)
    .reorder(published_at: :desc)
  end
end

CamaleonCms::CategoryDecorator.class_eval do

  def the_posts_cid
    self.posts.published
    .joins("LEFT OUTER JOIN cama_metas cm ON cm.objectid = cama_posts.id AND cm.object_class = 'Post' AND cm.key = 'enabled_languages'")
    .where("(#{CamaleonCms::Post.table_name}.published_at is not null and #{CamaleonCms::Post.table_name}.published_at <= ?)", Time.now)
    .where("visibility != 'private'")
    .where('cm.value is null or cm.value like ?', "%#{I18n.locale.to_s}%")
    .reorder(published_at: :desc)
  end

end

CamaleonCms::FrontendController.class_eval do 
  
  
  def search_cid
    breadcrumb_add(ct("search"))
    #items = params[:post_type_slugs].present? ? current_site.the_posts(params[:post_type_slugs].split(',')) : current_site.the_posts
    @cama_visited_search = true
    #@param_search = params[:q]
    layout_ = lookup_context.template_exists?("layouts/search") ? "search" : nil
    r = {layout: layout_, render: "search", posts: nil}; hooks_run("on_render_search", r)
    #params[:q] = (params[:q] || '').downcase
    #@posts = current_site.posts.published
    @posts = current_site.the_posts_cid
      
    unless (keyword = params[:q]).blank?
      @title = "#{ct('search_msg', default: 'Text searched: ')} #{params[:q]}"
      @posts = @posts.where("LOWER(title) LIKE ? OR LOWER(content_filtered) LIKE ?", "%#{keyword.downcase}%", "%#{keyword.downcase}%")
    end
    if d = params[:p]
      @posts = @posts.where("#{CamaleonCms::Post.table_name}.published_at > ? ", d.to_i.days.ago.beginning_of_day)
    end
    if categories = params[:c]
      @category = current_site.the_full_categories.find(params[:c].first).decorate
      if @title.blank? && categories.size.eql?(1)
        @title = @category.name
      end
      @posts = @posts.joins(:categories).where('categories_cama_posts.id': categories.map{|c| c.to_i})
    end
    @posts_size = @posts.size
    @post_published_at_min = @posts.select{|_| _.published_at.present?}.collect{|_| _.published_at}.min
    @post_published_at_max = @posts.select{|_| _.published_at.present?}.collect{|_| _.published_at}.max
    @posts = @posts.paginate(:page => params[:page], :per_page => current_site.front_per_page)
    render r[:render], (!r[:layout].nil? ? {layout: r[:layout]} : {})
  end
  
  def search_cp
    breadcrumb_add(ct("search"))
    #items = params[:post_type_slugs].present? ? current_site.the_posts(params[:post_type_slugs].split(',')) : current_site.the_posts
    @cama_visited_search = true
    #@param_search = params[:q]
    layout_ = lookup_context.template_exists?("layouts/search") ? "search" : nil
    r = {layout: layout_, render: "search", posts: nil}; hooks_run("on_render_search", r)
    #params[:q] = (params[:q] || '').downcase
    #@posts = current_site.posts.published
    @posts = current_site.the_posts('post').published
      .where("#{CamaleonCms::Post.table_name}.published_at <= ?", Time.now)
      .where("visibility != 'private'")
      .reorder(published_at: :desc)
    unless (keyword = params[:q]).blank?
      @title = "#{ct('search_msg', default: 'Text searched: ')} #{params[:q]}"
      @posts = @posts.where("LOWER(title) LIKE ? OR LOWER(content_filtered) LIKE ?", "%#{keyword.downcase}%", "%#{keyword.downcase}%")
    end
    if d = params[:p]
      @posts = @posts.where("#{CamaleonCms::Post.table_name}.published_at > ? ", d.to_i.days.ago.beginning_of_day)
    end
    if categories = params[:c]
      @category = current_site.the_full_categories.find(params[:c].first).decorate
      if @title.blank? && categories.size.eql?(1)
        @title = @category.name
      end
      @posts = @posts.joins(:categories).where('categories_cama_posts.id': categories.map{|c| c.to_i})
    end
    @posts_size = @posts.size
    @post_published_at_min = @posts.select{|_| _.published_at.present?}.collect{|_| _.published_at}.min
    @post_published_at_max = @posts.select{|_| _.published_at.present?}.collect{|_| _.published_at}.max
    @posts = @posts.paginate(:page => params[:page], :per_page => current_site.front_per_page)
    render r[:render], (!r[:layout].nil? ? {layout: r[:layout]} : {})
  end
  
  # render category list
  def category
    
    logger.debug "*****"
    logger.debug "*** Category List FOR CID ***" 
    logger.debug "*** Should not be used for CP ***" 
    logger.debug "*****"
    
    begin
      @category = current_site.the_full_categories.find(params[:category_id]).decorate
      @post_type = @category.the_post_type
    rescue
      return page_not_found
    end
    @cama_visited_category = @category
    @children = @category.children.no_empty.decorate
    @posts = @category.decorate.the_posts_cid  ## WARNING THIS IS FOR CID
      
    @posts_size = @posts.size
    @post_published_at_min = @posts.select{|_| _.published_at.present?}.collect{|_| _.published_at}.min
    @post_published_at_max = @posts.select{|_| _.published_at.present?}.collect{|_| _.published_at}.max
    @posts = @posts.paginate(:page => params[:page], :per_page => current_site.front_per_page).eager_load(:metas)
    
    respond_to do |format|
      
      format.html do
    
        r_file = lookup_context.template_exists?("category_#{@category.the_slug}") ? "category_#{@category.the_slug}" : nil  # specific template category with specific slug within a posttype
        r_file = lookup_context.template_exists?("post_types/#{@post_type.the_slug}/category") ? "post_types/#{@post_type.the_slug}/category" : nil unless r_file.present? # default template category for all categories within a posttype
        r_file = lookup_context.template_exists?("categories/#{@category.the_slug}") ? "categories/#{@category.the_slug}" : 'category' unless r_file.present?  # default template category for all categories for all posttypes

        layout_ = lookup_context.template_exists?("layouts/post_types/#{@post_type.the_slug}/category") ? "post_types/#{@post_type.the_slug}/category" : nil unless layout_.present? # layout for all categories within a posttype
        layout_ = lookup_context.template_exists?("layouts/categories/#{@category.the_slug}") ? "categories/#{@category.the_slug}" : nil unless layout_.present? # layout for categories for all post types
        r = {category: @category, layout: layout_, render: r_file}; hooks_run("on_render_category", r)
        render r[:render], (!r[:layout].nil? ? {layout: r[:layout]} : {})
      end
      
      format.js 
      
    end
  end
end