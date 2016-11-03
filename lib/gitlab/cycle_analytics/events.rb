module Gitlab
  module CycleAnalytics
    class Events
      include ActionView::Helpers::DateHelper

      def initialize(project:, from:)
        @project = project
        @from = from
        @fetcher = EventsFetcher.new(project: project, from: from)
      end

      def issue_events
        @fetcher.fetch(stage: :issue).each { |event| parse_event(event) }
      end

      def plan_events
        @fetcher.fetch(stage: :plan).each do |event|
          event['total_time'] = distance_of_time_in_words(event['total_time'].to_f)
          commit = first_time_reference_commit(event.delete('commits'), event)
          event['title'] = commit.title
          event['url'] =  Gitlab::LightUrlBuilder.build(entity: :commit_url, project: @project, id: commit.id)
          event['sha'] = commit.short_id
          event['author_name'] = commit.author.name
          event['author_profile_url'] = Gitlab::LightUrlBuilder.build(entity: :user, id: commit.author.username)
          event['author_avatar_url'] = Gitlab::LightUrlBuilder.build(entity: :user_avatar_url, id: commit.author.id)
        end
      end

      def code_events
        @fetcher.fetch(stage: :code).each { |event| parse_event(event) }
      end

      def test_events
        @fetcher.fetch(stage: :test).each do |event|
          event['total_time'] = distance_of_time_in_words(event['total_time'].to_f)
          event['pipeline'] = ::Ci::Pipeline.find_by_id(event['ci_commit_id']) # we may not have a pipeline
        end
      end

      def review_events
        @fetcher.fetch(stage: :review).each { |event| parse_event(event) }
      end

      def staging_events
        @fetcher.fetch(stage: :staging).each do |event|
          event['total_time'] = distance_of_time_in_words(event['total_time'].to_f)
          event['pipeline'] = ::Ci::Pipeline.find_by_id(event['ci_commit_id']) # we may not have a pipeline
        end
      end

      def production_events
        @fetcher.fetch(stage: :production).each { |event| parse_event(event) }
      end

      private

      def parse_event(event)
        event['url'] = Gitlab::LightUrlBuilder.build(entity: :issue, project: @project, id: event['id'])
        event['total_time'] = distance_of_time_in_words(event['total_time'].to_f)
        event['created_at'] = interval_in_words(event['created_at'])
        event['author_profile_url'] = Gitlab::LightUrlBuilder.build(entity: :user, id: event['author_username'])
        event['author_avatar_url'] = Gitlab::LightUrlBuilder.build(entity: :user_avatar_url, id: event['author_id'])

        event.except!('author_id', 'author_username')
      end

      def first_time_reference_commit(commits, event)
        st_commit = YAML.load(commits).detect do |commit|
          commit['created_at'] == event['first_mentioned_in_commit_at']
        end

        Commit.new(Gitlab::Git::Commit.new(st_commit), @project)
      end

      def interval_in_words(diff)
        "#{distance_of_time_in_words(diff.to_f)} ago"
      end
    end
  end
end
