require 'manage_iq/pundit_policy_class'

ActiveRecord::Base.send(:extend, ManageIQ::PunditPolicyClass)
