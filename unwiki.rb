# Remove empty wikis from GitHub repositories across a user/organization.
# Create a token here:
#
#   https://github.com/settings/tokens/new?description=unwiki&scopes=repo,public_repo
#
# then use it like so:
#
#   GITHUB_TOKEN=... USER=... ruby unwiki.rb

require 'octokit'


Octokit.auto_paginate = true
TOKEN = ENV.fetch('GITHUB_TOKEN')
CLIENT = Octokit::Client.new(access_token: TOKEN)
FORCE = !!ENV['FORCE']


def org?(login)
  user = CLIENT.user(login)
  user.type == 'Organization'
end

def repositories(login)
  if org?(login)
    CLIENT.organization_repositories(login, type: 'member')
  else
    CLIENT.repositories(login, type: 'owner')
  end
end

def git_endpoint_exists(url)
  # http://superuser.com/questions/227509/git-ping-check-if-remote-repository-exists
  system("git ls-remote --exit-code #{url} &> /dev/null")
end

def wiki_git_url(repo)
  "#{repo.html_url}.wiki.git"
end

def empty_wiki?(repo)
  url = wiki_git_url(repo)
  repo.has_wiki && !git_endpoint_exists(url)
end

def remove_wiki(repo)
  begin
    CLIENT.edit_repository(repo.full_name, has_wiki: false)
  rescue Octokit::NotFound
    puts "unable to remove wiki for #{repo.html_url}"
  else
    puts "removed wiki for #{repo.html_url}"
    exit
  end
end

def remove_wiki(repo)
  begin
    CLIENT.edit_repository(repo.full_name, has_wiki: false)
  rescue Octokit::NotFound
    puts "FAIL:    #{repo.html_url} (must be an admin)"
  else
    puts "SUCCESS: #{repo.html_url}"
  end
end

def remove_wiki_if_empty(repo)
  if empty_wiki?(repo)
    if FORCE
      remove_wiki(repo)
    else
      puts repo.html_url
    end
  end
end


USER = ENV.fetch('USER')
repos = repositories(USER)

if FORCE
  puts "Removing empty wikis..."
else
  puts "Listing repositories with empty wikis...run the same command with `FORCE=true` at the beginning to remove them."
end
puts "----------------"

repos.each do |repo|
  remove_wiki_if_empty(repo)
end

puts "DONE"
