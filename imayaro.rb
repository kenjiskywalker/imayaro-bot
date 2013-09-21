#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'logger'
require 'tweetstream'

log = Logger.new(STDOUT)
STDOUT.sync = true

TWITTER_CONSUMER_KEY        = ENV['TWITTER_CONSUMER_KEY']
TWITTER_CONSUMER_SECRET_KEY = ENV['TWITTER_CONSUMER_SECRET_KEY']
TWITTER_ACCESS_TOKEN        = ENV['TWITTER_ACCESS_TOKEN']
TWITTER_ACCESS_TOKEN_SECRET = ENV['TWITTER_ACCESS_TOKEN_SECRET']

# REST API
rest = Twitter::Client.new(
  :consumer_key       => TWITTER_CONSUMER_KEY,
  :consumer_secret    => TWITTER_CONSUMER_SECRET_KEY,
  :oauth_token        => TWITTER_ACCESS_TOKEN,
  :oauth_token_secret => TWITTER_ACCESS_TOKEN_SECRET,
)
# Streaming API
TweetStream.configure do |config|
  config.consumer_key       = TWITTER_CONSUMER_KEY,
  config.consumer_secret    = TWITTER_CONSUMER_SECRET_KEY,
  config.oauth_token        = TWITTER_ACCESS_TOKEN,
  config.oauth_token_secret = TWITTER_ACCESS_TOKEN_SECRET,
  config.auth_method        = :oauth
end

stream = TweetStream::Client.new

EM.error_handler do |e|
  log.error(e.message)
end

EM.run do
  # auto follow and unfollow (every 5 minutes)
  EM.add_periodic_timer(300) do

    log.info('em')

    friends   = rest.friend_ids.all
    followers = rest.follower_ids.all
    to_follow   = followers - friends
    to_unfollow = friends - followers

    log.info(to_follow)
    log.info(to_unfollow)

    # follow
    to_follow.each do |id|
      log.info('follow %s' % id)
      if rest.follow(id)
        log.info('done.')
      end
    end
    # unfollow
    to_unfollow.each do |id|
      log.info('unfollow %s' % id)
      if rest.unfollow(id)
        log.info('done.')
      end
    end
  end

  stream.on_inited do
    log.info('init')
  end
  stream.userstream do |status|
    next if status.retweet?
    next if status.reply?

    log.info('status from @%s: %s' % [status.from_user, status.text])

    n = rand(5)

    case n
    when 0
      yarou = 'それ、いまやりましょう'
    when 1
      yarou = 'いつやるんです？'
    when 2
      yarou = 'いますぐやりましょう！'
    when 3
      yarou = 'いまがその時です'
    when 4
      yarou = 'やりましょうナウ'
    end

    imayaro = '@%s ' % status.from_user
    case status.text
    when /したい$/
      imayaro += yarou
    when /りたい$/
      imayaro += yarou
    when /てみたい$/
      imayaro += yarou
    when /めたい$/
      imayaro += yarou
    else
      next
    end

    # 適当に間隔あける
    EM.add_timer(rand(5) + 5) do
      tweet = rest.update(imayaro, {
          :in_reply_to_status_id => status.id,
        })
      if tweet
        log.info('tweeted: %s' % tweet.text)
      end
    end
  end
end
