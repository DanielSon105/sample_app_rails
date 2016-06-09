class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: params[:session][:email].downcase)
    if user && user.authenticate(params[:session][:password])
      log_in user   # Log the user in
      params[:session][:remember_me] == '1' ? remember(user) : forget(user) # Remember the logged in user if box is checked
      redirect_to user # redirect to the user's show page
    else
      flash.now[:danger] = 'Invalid email/password combination'
      render 'new'
    end
  end

  def destroy
    log_out if logged_in?
    redirect_to root_url
  end
end
