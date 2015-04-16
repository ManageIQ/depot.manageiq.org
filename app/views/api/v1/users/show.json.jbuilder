json.username @user.username
json.name @user.name
json.company @user.company
json.github Array(@github_usernames)
json.twitter @user.twitter_username
json.irc @user.irc_nickname
json.jira @user.jira_username

json.tools do
  json.set! :owns do
    @owned_tools.each do |tool|
      json.set! tool.name, api_v1_tool_url(tool.slug)
    end
  end

  json.set! :collaborates do
    @collaborated_tools.each do |tool|
      json.set! tool.name, api_v1_tool_url(tool.slug)
    end
  end
end
