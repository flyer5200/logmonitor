module Concurrent
  module Actor
    module Behaviour

      # Handles `:await` messages. Which allows to wait on Actor to process all previously send
      # messages.
      # @example
      #   actor << :a << :b
      #   actor.ask(:await).wait # blocks until :a and :b are processed
      class Awaits < Abstract
        def on_envelope(envelope)
          if envelope.message == :await
            true
          else
            pass envelope
          end
        end
      end
    end
  end
end
