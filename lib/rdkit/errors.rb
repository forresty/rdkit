module RDKit
  class RDKitError < StandardError; end

  class ProtocolError < RDKitError; end
  class UnknownCommandError < ProtocolError; end
  class WrongNumberOfArgumentError < ProtocolError; end

  class SyntaxError < ProtocolError
    def self.exception; new('syntax error'); end
  end

  class UnknownSubcommandError < ProtocolError; end
  class WrongNumberOfArgumentForSubcommandError < ProtocolError; end

  class IllegalArgumentError < ProtocolError; end

  class IllegalClientNameError < IllegalArgumentError
    def self.exception; new('Client names cannot contain spaces, newlines or special characters.'); end
  end

  class ValueNotAnIntegerOrOutOfRangeError < IllegalArgumentError
    def self.exception; new('value is not an integer or out of range'); end
  end

  class ClientDisconnectedError < RDKitError; end
  class NoSuchClientError < RDKitError
    def self.exception; new('No such client'); end
  end

  class NotImplementedError < RDKitError; end

  class SDKRequirementNotMetError < RDKitError; end
  class ShouldOverrideError < SDKRequirementNotMetError; end
end
