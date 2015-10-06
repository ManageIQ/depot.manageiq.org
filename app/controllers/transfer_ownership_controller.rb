class TransferOwnershipController < ApplicationController
  before_filter :find_transfer_request, only: [:accept, :decline]

  #
  # PUT /extensions/:id/transfer_ownership
  #
  # Attempts to transfer ownership of extension to another user and redirects
  # back to the extension.
  #
  def transfer
    @extension = Extension.with_username_and_name(params[:username], params[:id])
    authorize! @extension, :transfer_ownership?
    recipient = @extension.transferrable_to_users.find(transfer_ownership_params[:user_id])
    msg = @extension.transfer_ownership(recipient)
    redirect_to extension_path(@extension, username: recipient.username), notice: t(msg, extension: @extension.name, user: recipient.username)
  end

  #
  # GET /ownership_transfer/:token/accept
  #
  # Accepts an OwnershipTransferRequest and redirects back to the extension.
  #
  def accept
    @transfer_request.accept!
    redirect_to @transfer_request.extension,
                notice: t(
                  'extension.ownership_transfer.invite_accepted',
                  extension: @transfer_request.extension.name
                )
  end

  #
  # GET /ownership_transfer/:token/decline
  #
  # Declines an OwnershipTransferRequest and redirects back to the extension.
  #
  def decline
    @transfer_request.decline!
    redirect_to @transfer_request.extension,
                notice: t(
                  'extension.ownership_transfer.invite_declined',
                  extension: @transfer_request.extension.name
                )
  end

  private

  #
  # Finds an OwnershipTransferRequest for the given token.
  #
  # Note that OwnershipTransferRequests that have already been accepted or
  # declined will not show up here and will generate a 404.
  #
  # @return [OwnershipTransferRequest]
  #
  def find_transfer_request
    @transfer_request = OwnershipTransferRequest.find_by!(
      token: params[:token],
      accepted: nil
    )
  end

  def transfer_ownership_params
    params.require(:extension).permit(:user_id)
  end
end
