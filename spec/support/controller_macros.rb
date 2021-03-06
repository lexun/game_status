module ControllerMacros
  def login_user
    before(:each) do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      user = create(:han_solo)
      user.confirm!
      sign_in user
    end
  end
end