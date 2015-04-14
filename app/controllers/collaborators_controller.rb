class CollaboratorsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_collaborator, only: [:destroy, :transfer]
  skip_before_filter :verify_authenticity_token, only: [:destroy]

  #
  # GET /collaborators?q=jimmy&ineligible_user_ids=[1,2,3]
  #
  # Searches for someone by username, limited to potential collaborators or owners
  # for a given resource.
  #
  def index
    @collaborators = User.includes(:chef_account).
      where.not(id: params[:ineligible_user_ids]).
      limit(20)

    if params[:q]
      @collaborators = @collaborators.search(params[:q])
    end

    respond_to do |format|
      format.json
    end
  end

  #
  # POST /collaborators
  #
  # Add a collaborator to a resource.
  #
  def create
    if %w(Cookbook Tool).include?(collaborator_params[:resourceable_type])
      resource = collaborator_params[:resourceable_type].constantize.find(
        collaborator_params[:resourceable_id]
      )

      user_ids = collaborator_params.delete(:user_ids).split(',') -
        Collaborator.ineligible_collaborators_for(resource).map(&:id).map(&:to_s)

      User.where(id: user_ids).each do |user|
        collaborator = Collaborator.new(
          collaborator_params.merge(user_id: user.id)
        )

        authorize! collaborator
        collaborator.save!

        CollaboratorMailer.delay.added_email(collaborator)
      end

      redirect_to resource, notice: t('collaborator.added')
    else
      not_found!
    end
  end

  #
  # DELETE /collaborators/:id
  #
  # Remove a single collaborator.
  #
  def destroy
    respond_to do |format|
      format.js do
        authorize!(@collaborator)

        @collaborator.destroy
        head :ok
      end
    end
  end

  #
  # PUT /collaborators/:id/transfer
  #
  # Transfers ownership of the resource to a collaborator, thereby demoting the
  # owner to a collaborator.
  #
  def transfer
    authorize!(@collaborator)

    @collaborator.transfer_ownership

    redirect_to(
      @collaborator.resourceable,
      notice: t('collaborator.owner_changed',
                resource: @collaborator.resourceable.name,
                user: @collaborator.user.username)
    )
  end

  private

  #
  # Find the CookbookCollaborator from an existing Cookbook and User
  #
  # @return [CookbookCollaborator]
  #
  def find_collaborator
    @collaborator = Collaborator.find(params[:id])
  end

  #
  # Params used when creating one or more +Collaborator+.
  #
  def collaborator_params
    params.require(:collaborator).permit([
      :resourceable_type,
      :resourceable_id,
      :user_ids
    ])
  end
end
