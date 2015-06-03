require 'spec_helper'

describe TransferOwnershipController do
  describe 'PUT #transfer' do
    let(:extension) { create(:extension) }
    let(:new_owner) { create(:user) }

    before do
      extension_collection = double('extension_collection', :first! => extension)
      allow(Extension).to receive(:with_name) { extension_collection }
    end

    shared_examples 'admin_or_owner' do
      before { sign_in(user) }

      it 'attempts to change the extensions owner' do
        expect(extension).to receive(:transfer_ownership).with(
          user,
          new_owner
        ) { 'extension.ownership_transfer.done' }
        put :transfer, id: extension, extension: { user_id: new_owner.id }
      end

      it 'redirects back to the extension' do
        put :transfer, id: extension, extension: { user_id: new_owner.id }
        expect(response).to redirect_to(assigns[:extension])
      end
    end

    context 'the current user is an admin' do
      let(:user) { create(:admin) }
      it_behaves_like 'admin_or_owner'
    end

    context 'the current user is the extension owner' do
      let(:user) { extension.owner }
      it_behaves_like 'admin_or_owner'
    end

    context 'the current user is not an admin nor an owner of the extension' do
      before { sign_in(create(:user)) }

      it 'returns a 404' do
        put :transfer, id: extension, extension: { user_id: new_owner.id }
        expect(response.status.to_i).to eql(404)
      end
    end
  end

  context 'transfer requests' do
    let(:transfer_request) { create(:ownership_transfer_request) }

    shared_examples 'a transfer request' do
      it 'redirects back to the extension' do
        post :accept, token: transfer_request
        expect(response).to redirect_to(assigns[:transfer_request].extension)
      end

      it 'finds transfer requests based on token' do
        post :accept, token: transfer_request
        expect(assigns[:transfer_request]).to eql(transfer_request)
      end

      it 'returns a 404 if the transfer request given has already been updated' do
        transfer_request.update_attribute(:accepted, true)
        post :accept, token: transfer_request
        expect(response.status.to_i).to eql(404)
      end
    end

    describe 'GET #accept' do
      it 'attempts to accept the transfer request' do
        allow(OwnershipTransferRequest).to receive(:find_by!) { transfer_request }
        expect(transfer_request.accepted).to be_nil
        expect(transfer_request).to receive(:accept!)
        get :accept, token: transfer_request
      end

      it_behaves_like 'a transfer request'
    end

    describe 'GET #decline' do
      it 'attempts to decline the transfer request' do
        allow(OwnershipTransferRequest).to receive(:find_by!) { transfer_request }
        expect(transfer_request.accepted).to be_nil
        expect(transfer_request).to receive(:decline!)
        get :decline, token: transfer_request
      end

      it_behaves_like 'a transfer request'
    end
  end
end
