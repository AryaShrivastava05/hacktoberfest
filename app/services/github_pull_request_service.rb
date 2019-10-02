# frozen_string_literal: true

# Fetches Pull Requests for a user from the GitHub API
# Returns an array of GraphqlPullRequest instances
class GithubPullRequestService
  attr_reader :user

  PULL_REQUEST_QUERY = <<~GRAPHQL
    query($nodeId:ID!){
      node(id:$nodeId) {
        ... on User {
          pullRequests(states: [OPEN, MERGED, CLOSED] last: 100) {
            nodes {
              id
              title
              body
              url
              createdAt
              repository{
                databaseId
              }
              labels(first: 100) {
                edges {
                  node {
                    name
                  }
                }
              }
            }
          }
        }
      }
    }
  GRAPHQL

  def initialize(user)
    @user = user
  end

  def pull_requests
    return @pull_requests if @pull_requests.present?

    response = Rails.cache.fetch(cache_key, expires_in: 15.minutes) do
      client.request(PULL_REQUEST_QUERY, nodeId: user_graphql_node_id)
    end

    @pull_requests = response.data.node.pullRequests.nodes.map do |pr|
      GithubPullRequest.new(pr)
    end
  end

  private

  def cache_key
    "user/#{@user.id}/github_pull_request_service/response"
  end

  def client
    @client ||= GithubGraphqlApiClient.new(access_token: @user.provider_token)
  end

  def user_graphql_node_id
    encode_string = "04:User#{@user.uid}"
    Base64.encode64(encode_string).chomp
  end
end
