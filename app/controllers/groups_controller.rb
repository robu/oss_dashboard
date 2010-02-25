class GroupsController < ApplicationController
  caches_page :show
  
  def index
    # TODO actually support listing of groups
    redirect_to :action => 'dashboard', :id => Group.last.id
  end

  def show
    @group = Group.find(params[:id])
  end
  
  def dashboard
    @group = Group.find(params[:id])

    @projects = @group.projects.approved.sort_by(&:age)
    
    # generate statistics
    @stats = {}
    @stats['num_projects'] = @projects.size
    @stats['none'] = @projects.reject{|p| p.blog || p.wiki || p.source_code}.size
    @stats['all_three'] = @projects.select{|p| p.blog && p.wiki && p.source_code}.size
    @stats['last_week'] = @projects.select{|p| [p.blog_age, p.source_code_age].min < 7}.size
    @stats['members'] =  @projects.map(&:contributors).map{|c| c.split(/, ?/)}.flatten.uniq.count
  end

  def admin
    @group = Group.find(params[:id], :include => [:projects])
  end
  
  def fetch
    @group = Group.find(params[:id])
    @group.fetch
    expire_page :action => 'show', :id => @group.id
    expire_page :controller => 'events', :action => 'index'
    redirect_to :action => 'dashboard', :id => params[:id]
  end
  
  def laggards
    @group = Group.find(params[:id], :include => [:projects])
    @projects = @group.projects.find_all do |project|
      project.blog_age > 14 || project.source_code_age > 14
    end
  end
  
  def authenticate
    @group = Group.find(params[:id])
    if request.post?
      if params[:admin_password] == @group.admin_password
        session[:admin_for_groups] ||= []
        session[:admin_for_groups] << @group.id
        @next = true
      else
        flash[:notice] = "Access denied"
        redirect_to :back
      end
    end
  end
end