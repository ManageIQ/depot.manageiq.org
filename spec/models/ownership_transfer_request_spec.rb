require 'spec_helper'

describe OwnershipTransferRequest do
  context 'associations' do
    it { should belong_to(:cookbook) }
    it { should belong_to(:recipient) }
    it { should belong_to(:sender) }
  end

  context 'validations' do
    it { should validate_presence_of(:cookbook) }
    it { should validate_presence_of(:recipient) }
    it { should validate_presence_of(:sender) }
  end

  it 'should have a token by default' do
    otr = build(:ownership_transfer_request)
    expect(otr).to be_valid
    expect(otr.token).to be_present
  end

  context 'accept and decline' do
    let(:transfer_request) { create(:ownership_transfer_request) }

    shared_examples 'returning early' do
      it 'should not do anything if it has already been accepted or declined' do
        transfer_request.update_attribute(:accepted, false)
        transfer_request.reload
        expect(transfer_request).to_not receive(:update_attribute)
        transfer_request.accept!
        transfer_request.reload
        expect(transfer_request.accepted).to eql(false)
      end
    end

    describe '#accept!' do
      it 'should mark itself as accepted' do
        expect(transfer_request.accepted).to be_nil
        transfer_request.accept!
        transfer_request.reload
        expect(transfer_request.accepted).to eql(true)
      end

      it 'should transfer ownership to someone else' do
        cookbook = transfer_request.cookbook
        sally = cookbook.owner
        jimmy = transfer_request.recipient
        transfer_request.accept!
        cookbook.reload
        expect(cookbook.owner).to eql(jimmy)
      end

      it_should_behave_like 'returning early'
    end

    describe '#decline!' do
      it 'should mark itself as declined' do
        expect(transfer_request.accepted).to be_nil
        transfer_request.decline!
        transfer_request.reload
        expect(transfer_request.accepted).to eql(false)
      end

      it_should_behave_like 'returning early'
    end
  end
end
