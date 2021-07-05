class RemindersController < BasePublicController
  def new
    @reminder = Reminder.new
    render "personal-details".underscore
  end

  def create
    @reminder = Reminder.new(reminder_params)

    if @reminder.save(context: :"personal-details")
      redirect_to reminder_path
    else
      render "personal-details".underscore
    end
  end

  def show
    render "eligible-later-completion".underscore
  end

  private

  def reminder_params
    params.require(:reminder).permit(:full_name, :email_address)
  end
end
