module ApplicationHelper
  # I hate those deprecation warnings -.-
  def link_to_function(name, *args, &block)
    html_options = args.extract_options!.symbolize_keys

    function = block_given? ? update_page(&block) : args[0] || ''
    onclick = "#{"#{html_options[:onclick]}; " if html_options[:onclick]}#{function}; return false;"
    href = html_options[:href] || '#'

    content_tag(:a, name, html_options.merge(:href => href, :onclick => onclick))
  end

  def link_to( body, url, attrs = {})
    attrs =  { :title => body }.merge(attrs)
    super
  end

  def link_icon_to( body, icon, url, attrs = {} )
    attrs =  { :title => body, :class => 'iconic' }.merge(attrs)    
    link_to "<i class=\"icon-#{icon}\"></i> #{body}".html_safe, url, attrs
  end

  def link_icon_to_function( body, icon, js, attrs = {} )
    attrs = { :class => 'iconic' }.merge(attrs)
    link_to_function "<i class=\"icon-#{icon}\"></i> #{body}".html_safe, js, attrs
  end

  def navbar_language_link( language )
    # if we are not under a specific language archive, obtain current 
    # language from the current shown source if any
    @language ||= if @source then @source.language else nil end
    attrs = if @language && @language == language
              { :class => 'current' }
            else
              {}
            end

    link_to language.title, language_archive_path(language.name), attrs
  end

  def tag_with_class_if( tag, clazz, condition, attributes = {}, &block )
    if condition
      attributes['class'] = clazz
    end

    content_tag( tag, attributes, &block )
  end

  def page_title
    base_title = 'emoticode'
    subtitle   = 'Snippets and Source Code Search Engine'

    page_title = if @source and !@source.new_record?
                   "#{@source.language.title} - #{@source.title} | #{base_title}"

                 elsif @language
                   "#{@language.title} Snippets | #{base_title}"

                 elsif @user and !@user.new_record?
                   "#{@user.username} | #{base_title}"

                 elsif @phrase
                   "Search '#{@phrase}' | #{base_title}"

                 else
                   "#{base_title} - #{subtitle}"
                 end

    if params[:page].to_i > 1 
      page_title << " ( Page #{params[:page]} )"
    end

    page_title
  end

  def metas
    title       = page_title
    description = "EmotiCODE is a code snippet search engine but mostly a place where developers can find help for what they need and contribute with their own contents."
    keywords    = "emoticode, snippets, code snippets, source, source code, programming, programmer, #{@languages.map(&:title).join(', ')}"

    if @source and !@source.new_record?
      keywords    = @source.tags.map(&:value).join(', ')
      description = if !@source.description.nil? && !@source.description.empty?
                      @source.description
                    else
                      title
                    end

    elsif @language
      description = "#{@language.title} Snippets from EmotiCODE, a #{@language.title} code snippet search engine but mostly a place where developers can find help for what they need and contribute with their own contents."
      keywords    = "#{@language.title} snippets, #{@language.title} code, #{@language.title} codes, #{@language.title} code snippets, #{@language.title} snippet archive" 

    elsif @user and !@user.new_record?
      description = "#{@user.username} EmotiCODE Profile"

    elsif @phrase
      description = "Searching for #{@phrase} inside EmotiCODE, a source code snippet search engine but mostly a place where developers can find help for what they need and contribute with their own contents." 

    end

    if params[:page].to_i > 1 
      description << " ( Page #{params[:page]} )"
    end

    [
      { charset: 'utf-8' },
      { property: 'og:locale', content: 'en_US' },
      { property: 'og:site_name', content: 'emoticode' },
      { property: 'og:image', content:'http://www.emoticode.net/assets/style/logo-200.png?v=2.1' },
      { property: 'og:description', content: description },
      { property: 'fb_app_id', content: '541383999216397' },
      { property: 'fb:app_id', content: '541383999216397' },
      { property: 'og:url', content: 'http://www.emoticode.net/' },
      { name: 'language', content: 'en' },
      { name: 'title', content: title },
      { name: 'description', content: description },
      { name: 'keywords', content: keywords },
      { name: 'robots', content: 'noodp,noydr' },
      { name: 'alexaVerifyID', content: 'esKfarSO5NWalbJaefzTwaUzso' },
      { name: 'msvalidate.01', content: '9C2A48C8F5733D97CD13C5EB3699308D' },
      { name: 'google-site-verification', content: 'Uy9LP869XtH59q7mfCgyOd4CS5XifoRgROn0wJ8d8MU' }
    ]
  end 

  def modal_dialog( id, title )
    content_tag :div, :class => 'dialog', :id => id do
      content_tag( :div, :class => 'title' ) { title } +
      content_tag( :div, :class => 'content' ) do
        yield
      end
    end 
  end

  def tag_cloud( tags, min_size = 9, max_size = 20 )
    min_occurs = tags.map(&:sources_count).min
    max_occurs = tags.map(&:sources_count).max
    cloud = {}

    tags.each do |tag|
      weight = ( Math.log(tag.sources_count) - Math.log(min_occurs) ) / ( Math.log(max_occurs) - Math.log(min_occurs) )
      size   = weight.nan? ? min_size : min_size + ( ( max_size - min_size ) * weight ).round
      cloud[tag.value] = [ tag, size, tag.sources_count ]
    end

    cloud
  end

  def signed_in?
    !@current_user.nil?
  end

  def avatar_tag(user)
    image_tag user.avatar, :class => 'avatar', :alt => "#{user.username} avatar."
  end

  def nested_comments(object)
    # select every comment for this object
    comments = object.comments.order('created_at DESC')
    # get root objects ( with no parent )
    threads  = comments.select { |c| c.parent_id.nil? }
    # recurse every thread and group comments by their parents
    nested   = threads.map { |root| group_comments root, comments }
  end

  private 

  def group_comments( parent, comments )
    comments.each do |comment|
      if parent.id == comment.parent_id
        parent.children << group_comments( comment, comments )
      end
    end

    parent
  end
end
