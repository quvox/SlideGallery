# coding: utf-8
class GalleryController < ApplicationController
  skip_before_filter :verify_authenticity_token ,:only=>[:upload_file]
  @@openoffice = `which libreoffice`.chomp
  @@pdftotext = `which pdftotext`.chomp
  
  def initialize
    super
    FileUtils.mkdir_p("public/orig") unless FileTest.exist?("public/orig")
    FileUtils.mkdir_p("public/pdf") unless FileTest.exist?("public/pdf")
  end

  def index
    @pagenum = params[:page]
    if @pagenum == nil
      @sidlist = Tag.all.select(:slideid).pluck(:slideid).uniq
      @slideList = Slide.order('created_at DESC').select("*").page(1)
      @ownersList = Slide.select(:user).pluck(:user).uniq
      @currentTags = Tag.select(:tagname).uniq.pluck(:tagname)
      @selectedTags = []
      @searchKeyword = ""
      preserveSession
    else
      pg = @pagenum
      restoreSession
      @slideList = Slide.where(id: @sidlist).where(user: @ownersList).order('created_at DESC').select("*").page(pg)
      @pagenum = pg
      preserveSession
    end

    render
  end

  def get_slides
    p params.inspect
    if params.key?(:tag)
      narrowdown_by_tag(params[:tag], @pagenum, nil)
    elsif params.key?(:user)
      narrowdown_by_user(params[:user], @pagenum)
    elsif params.key?(:keyword)
      narrowdown_by_keyword(params[:keyword], @pagenum)
    end
  end

  def get_tags
  end

  def update_slide
    if ! params.key?(:slideid)
      render json: {'success' => false, 'reason' => 'Something wrong (no ID)..'}
      return
    end
    entry = Slide.where("id = ?", params[:slideid]).first
    #puts entry.inspect
    if entry.user != params[:user]
      render json: {'success' => false, 'reason' => 'User mismatch'}
      return
    end
    if params[:pass] != entry.pass
      render json: {'success' => false, 'reason' =>  'Password mismatch'}
      return
    end
    entry.title = params[:title]
    register_tags(params[:tags], entry.id)
    entry.save    
    render json: {'success' => true}
  end
  
  def delete_slide
    if ! params.key?(:slideid)
      render json: {'success' => false, 'reason' => 'Something wrong (no ID)..'}
      return
    end
    entry = Slide.where("id = ?", params[:slideid]).first
    if entry.user != params[:user]
      render json: {'success' => false, 'reason' => 'User mismatch'}
      return
    end
    if entry.pass != "" && params[:pass] != entry.pass
      render json: {'success' => false, 'reason' => 'Password mismatch'}
      return
    end
    s = Slide.where("id = ?", params[:slideid]).first
    `rm -f public/pdf/#{s.id}.pdf`
    `rm -f public/orig/#{s.id}.*`
    Slide.delete(params[:slideid])
    Tag.destroy_all(slideid: params[:slideid])
    Keyword.destroy_all(slideid: params[:slideid])
    render json: {'success' => true}
  end

  def upload_file
    if params.key?(:fileupload)
      file = params[:file]
      fileName = file.original_filename
      fileContent = file.read
      extname = File.extname(fileName)
      if extname != ".pdf" && @@openoffice == "" then
        render :json => {'success' => false, 'reason' => 'Could not convert to pdf (please contact the super user).'}
        return
      end
      id = register_new_file(fileName, fileContent, params[:title], params[:user], params[:pass])
      register_tags(params[:tags], id)
    else
      render :json => {'success' => false, 'reason' => 'Something wrong. Fail to upload.'}
      return
    end
    render :json => {'success' => true}
  end
  
  def download_file
    entry = Slide.where("id = ?", params[:slideid]).first
    send_file("public/"+entry.path, filename: entry.filename, disposition: 'attachment')
  end

  def get_slide_info
    @slide = Slide.where("id = ?", params[:slideid]).first
    if @slide == nil
      @slide = Slide.new
    end
    tarray = []
    Tag.all.where("slideid = ?", params[:slideid]).each do |t|
      tarray.push(t.tagname)
    end
    @tags = tarray.join(",")
  end

  def export
    FileUtils.mkdir_p("public/export") unless FileTest.exist?("public/export")
    `rm -f public/export/*`
    Slide.all.select("*").each do |sl|
      fn = File::basename(sl.path)
      filename = "#{sl.id}_#{fn}"
      `cp public/#{sl.path} public/export/#{filename}`
    end
    render
  end

private
  def register_new_file(fileName, fileContent, title, user, pass)
    entry = Slide.new
    entry.save
    id = entry.id
    entry.title = title
    entry.user = user
    entry.pass = pass
    extname = File.extname(fileName)
    if extname == ".pdf"
      entry.path = "pdf/#{id}.pdf"
    else
      entry.path = "orig/#{id}#{extname}"
    end
    entry.filename = fileName
    File.binwrite("public/"+entry.path, fileContent)
    entry.save
    
    if extname != ".pdf" && @@openoffice != ""
      #logger.debug `#{@@openoffice} --nologo --headless --nofirststartwizard –-convert-to pdf -outdir public/pdf/ public/#{entry.path}`
      logger.debug `sh bin/pdfout.sh #{entry.path}`
    end

    if @@pdftotext != "" && File.exist?("public/pdf/#{id}.pdf")
      textinfo = `#{@@pdftotext} "public/pdf/#{id}.pdf" -`.split(/\n|\s{2,}/)
      textinfo.each do |t|
        t = t.gsub(/•\s*/,"")
        if t =~ /^\s*$/ || t =~ /^\d*$/ || t.length < 3 then next end
        k = Keyword.new
        k.slideid = id
        k.word = t
        k.save
      end
    end

    return id
  end

  def register_tags(taginfo, id)
    Tag.destroy_all("slideid = '#{id}'")
    taginfo.split(",").each do |t|
      tg = Tag.new
      tg.tagname = t
      tg.slideid = id
      tg.save
    end
  end
  
  def preserveSession
    session[:sidlist] = @sidlist
    session[:currenttags] = @currentTags
    session[:selectedtags] = @selectedTags
    session[:owners] = @ownersList
    session[:keyword] = @searchKeyword
    session[:page] = @pagenum
  end

  def restoreSession
    @sidlist = session[:sidlist]
    @currentTags = session[:currenttags]
    @selectedTags = session[:selectedtags]
    @ownersList = session[:owners]
    @searchKeyword = session[:keyword]
    @pagenum = session[:page]
  end
  
  def narrowdown_by_tag(tag, pg, user)
    restoreSession

    if @selectedTags == nil then @selectedTags = [] end
    if tag != nil then @selectedTags.push(tag) end

    @sidlist = Tag.all.select(:slideid).pluck(:slideid).uniq
    @selectedTags.each do |t|
      s = Tag.all.select(:slideid).where(tagname: t).pluck(:slideid).uniq
      @sidlist = @sidlist & s
    end

    if user == nil
      @ownersList = Slide.where(id: @sidlist).select(:user).pluck(:user).uniq
    else
      @ownersList = [user]
    end
    @slideList = Slide.where(id: @sidlist).where(user: @ownersList).order('created_at DESC').select("*").page(pg)
    @currentTags = Tag.select(:tagname).where(slideid: @slideList.pluck(:id).uniq).where.not(tagname: @selectedTags).pluck(:tagname).uniq

    preserveSession
  end

  def narrowdown_by_user(user, pg)
    narrowdown_by_tag(nil, pg, user)
  end

  def narrowdown_by_keyword(words, pg)
    @sidlist = Keyword.search(words).select(:slideid).pluck(:slideid).uniq
    @slideList = Slide.where(id: @sidlist).order('created_at DESC').select("*").page(pg)
    @currentTags = Tag.select(:tagname).where(slideid: @slideList.pluck(:id).uniq).where.not(tagname: @selectedTags).pluck(:tagname).uniq
    @ownersList = Slide.where(id: @sidlist).select(:user).pluck(:user).uniq
    @searchKeyword = words
    preserveSession
  end
end
