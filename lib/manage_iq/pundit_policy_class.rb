module ManageIQ
  module PunditPolicyClass
    extend ActiveSupport::Concern

    def policy_class
      "#{name}Authorizer"
    end
  end
end
