require "spec_helper"

describe Object do
  it { is_expected.to respond_to :try }
end

describe NilClass do
  subject { nil }
  it { is_expected.to respond_to :try }
end
