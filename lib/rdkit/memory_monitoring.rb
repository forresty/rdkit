require 'newrelic_rpm'

module RDKit
  module MemoryMonitoring
    @@peak_memory = 0

    def used_memory_rss_in_mb
      update_peak_memory!

      '%0.2f' % used_memory_rss + 'M'
    end

    def used_memory_peak_in_mb
      '%0.2f' % @@peak_memory + 'M'
    end

    private

    def update_peak_memory!
      @@peak_memory = [@@peak_memory, used_memory_rss].max
    end

    def used_memory_rss
      @@sampler ||= NewRelic::Agent::Samplers::MemorySampler.new.sampler

      @@sampler.get_sample
    end
  end
end
