module ProtectedBranchAccess
  extend ActiveSupport::Concern

  included do
    include ProtectedRefAccess
<<<<<<< HEAD
    include EE::ProtectedBranchAccess
=======
>>>>>>> ce/master

    belongs_to :protected_branch

    delegate :project, to: :protected_branch
  end
end
