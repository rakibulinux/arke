# frozen_string_literal: true

module Arke::ETL
  class Reactor
    class StrategyNotFound < StandardError; end

    def initialize(config, dry_run)
      @shutdown = false
      @dry_run = dry_run
      init_jobs(config)
    end

    def assert_array(node, key)
      raise "configuration error: `#{key}` must be an array" \
        unless node[key].is_a?(Array)
    end

    def assert_string_or_hash(node, key)
      raise "configuration error: `#{key}` must be a string or a hash" \
        if !node[key].is_a?(String) && !node[key].is_a?(Hash)
    end

    def assert_string_array_hash_or_absent(node, key)
      return [node[key]] if node[key].is_a?(Hash)

      raise "configuration error: `#{key}` must be a string, a hash, an array or be absent" \
        if !node[key].is_a?(String) && !node[key].is_a?(Array) && !node[key].nil?

      Array(node[key])
    end

    def klass(element, konstant)
      return [konstant.const_get(element), {}] \
        if element.is_a?(String)

      return [konstant.const_get(element.keys.first), element.values.first] \
        if element.is_a?(Hash) && element.size == 1

      raise "wrong klass element: #{element.inspect}"
    end

    def new_klass(element, konstant)
      Arke::Log.debug("")
      const, config = klass(element, konstant)
      const.new(config)
    end

    def init_jobs(config)
      @extractors = []
      jobs = config["jobs"]
      assert_array(config, "jobs")

      jobs.each do |job|
        assert_string_or_hash(job, "extract")
        assert_array(job, "process")
        extract = new_klass(job["extract"], Arke::ETL::Extract)
        @extractors << extract

        post_process_upstream = extract

        transforms = assert_string_array_hash_or_absent(job, "transform")
        transforms.each do |t|
          transform = new_klass(t, Arke::ETL::Transform)
          post_process_upstream.mount(&transform.method(:call))
          post_process_upstream = transform
        end

        job["process"].each do |p|
          upstream = post_process_upstream
          transforms = assert_string_array_hash_or_absent(p, "transform")
          transforms.each do |t|
            transform = new_klass(t, Arke::ETL::Transform)
            upstream.mount(&transform.method(:call))
            upstream = transform
          end
          assert_string_or_hash(p, "load")

          load_instance = new_klass(p["load"], Arke::ETL::Load)
          upstream.mount(&load_instance.method(:call))
        end
      end
    end

    def run
      EM.synchrony do
        trap("INT") { stop }

        @extractors.each do |extract|
          Fiber.new do
            extract.start
          end.resume
        end
      end
    end

    def stop
      puts "Shutting down"
      @shutdown = true
      exit(42)
    end
  end
end
