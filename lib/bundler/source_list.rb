module Bundler
  class SourceList
    attr_reader :path_sources,
                :git_sources,
                :svn_sources,
                :rubygems_sources

    def initialize
      @path_sources       = []
      @git_sources        = []
      @svn_sources        = []
      @rubygems_aggregate = Source::Rubygems.new
      @rubygems_sources   = [@rubygems_aggregate]
    end

    def add_path_source(options = {})
      add_source_to_list Source::Path.new(options), path_sources
    end

    def add_git_source(options = {})
      add_source_to_list Source::Git.new(options), git_sources
    end

    def add_svn_source(options = {})
      add_source_to_list Source::SVN.new(options), svn_sources
    end

    def add_rubygems_source(options = {})
      add_source_to_list Source::Rubygems.new(options), @rubygems_sources
    end

    def add_rubygems_remote(uri)
      @rubygems_aggregate.add_remote(uri)
      @rubygems_aggregate
    end

    def all_sources
      path_sources + git_sources + svn_sources + rubygems_sources
    end

    def get(source)
      source_list_for(source).find { |s| source == s }
    end

    def lock_sources
      (path_sources + git_sources + svn_sources) << combine_rubygems_sources
    end

    def replace_sources!(replacement_sources)
      [path_sources, git_sources, svn_sources, rubygems_sources].each do |source_list|
        source_list.map! do |source|
          replacement_sources.find { |s| s == source } || source
        end
      end
    end

    def cached!
      all_sources.each(&:cached!)
    end

    def remote!
      all_sources.each(&:remote!)
    end

  private

    def add_source_to_list(source, list)
      list.unshift(source).uniq!
      source
    end

    def source_list_for(source)
      case source
      when Source::Git      then git_sources
      when Source::SVN      then svn_sources
      when Source::Path     then path_sources
      when Source::Rubygems then rubygems_sources
      else raise ArgumentError, "Invalid source: #{source.inspect}"
      end
    end

    def combine_rubygems_sources
      Source::Rubygems.new("remotes" => rubygems_sources.map(&:remotes).flatten.uniq.reverse)
    end
  end
end
