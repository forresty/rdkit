module RDKit
  class RDKitError < StandardError; end

  class ProtocolError < RDKitError; end
  class UnknownCommandError < ProtocolError; end
  class WrongNumberOfArgumentError < ProtocolError; end

  class UnknownSubcommandError < ProtocolError; end
  class WrongNumberOfArgumentForSubcommandError < ProtocolError; end

  class IllegalArgumentError < ProtocolError; end

  class ClientDisconnectedError < RDKitError; end

  class NotImplementedError < RDKitError; end

  class SDKRequirementNotMetError < RDKitError; end
  class ShouldOverrideError < SDKRequirementNotMetError; end
end
