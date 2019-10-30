# frozen_string_literal: true

require 'octokit'

module ImportUserMetadataService
  module_function

  def call(user)
    access_token = GithubTokenService.random
    api_client = Octokit::Client.new(access_token: access_token)

    user_data = api_client.user(user.name).to_hash

    UserStat.where(user_id: user.id).first_or_create(data: user_data)
  end
end
