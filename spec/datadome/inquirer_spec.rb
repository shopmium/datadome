# frozen_string_literal: true

require "spec_helper"

RSpec.describe Datadome::Inquirer do
  let(:env) do
    {
      "SERVER_SOFTWARE" => "thin 1.7.2 codename Bachmanity",
      "SERVER_NAME" => "www.my-domain.com",
      "rack.input" => StringIO.new("the body"),
      "rack.version" => [1, 0],
      # "rack.errors"=>#<IO:<STDERR>>,
      "rack.multithread" => false,
      "rack.multiprocess" => false,
      "rack.run_once" => false,
      "REQUEST_METHOD" => "GET",
      "REQUEST_PATH" => "/my/path",
      "PATH_INFO" => "/my/path",
      "QUERY_STRING" => "foo=bar&baz=1",
      "REQUEST_URI" => "/my/path?foo=bar&baz=1",
      "HTTP_VERSION" => "HTTP/1.1",
      "HTTP_HOST" => "www.my-domain.com",
      "HTTP_CONNECTION" => "keep-alive",
      "HTTP_PRAGMA" => "no-cache",
      "HTTP_CACHE_CONTROL" => "no-cache, no-store, must-revalidate",
      "HTTP_ACCEPT" => "*/*",
      "HTTP_X_CSRF_TOKEN" => "p8NNwjcp0NBxO7hf5Y4jj10alFvIuE6qCHxGbz4tvNI3FHjZMutWhOJodqgneFKt9cSs1pRNq6Tbe7t1MqqYmA==",
      "HTTP_USER_AGENT" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36",
      "HTTP_X_REQUESTED_WITH" => "XMLHttpRequest",
      "HTTP_X_FORWARDED_FOR" => "12.23.34.45",
      "HTTP_ORIGIN" => "www.my-origin-domain.com",
      "HTTP_REFERER" => "http://www.other-domain.com/other/path",
      "HTTP_ACCEPT_CHARSET" => "utf-8, iso-8859-1;q=0.5",
      "HTTP_ACCEPT_ENCODING" => "gzip, deflate",
      "HTTP_ACCEPT_LANGUAGE" => "fr-FR,fr;q=0.8,en-US;q=0.6,en;q=0.4",
      "HTTP_COOKIE" => "foo=bar; datadome=AHrlqAAAAAMA9RBP7xmrgZcAAAAAAA%3D%3D; baz=bar",
      "GATEWAY_INTERFACE" => "CGI/1.2",
      "SERVER_PORT" => "80",
      "SERVER_PROTOCOL" => "HTTP/1.1",
      "rack.url_scheme" => "http",
      "SCRIPT_NAME" => "",
      "REMOTE_ADDR" => "192.168.1.1",
      "ORIGINAL_FULLPATH" => "/my/path?foo=bar&baz=1",
      "ORIGINAL_SCRIPT_NAME" => "",
    }
  end

  let(:exclude_matchers) { [] }
  let(:include_matchers) { [] }
  let(:monitoring_mode) { false }

  subject { described_class.new(env, exclude_matchers: exclude_matchers, include_matchers: include_matchers, monitoring_mode: monitoring_mode) }

  describe "#ignore?" do
    context "without matchers" do
      it "returns false" do
        expect(subject.ignore?).to eq(false)
      end
    end

    context "with an exclude matcher" do
      let(:exclude_matchers) {
        [
          ->(host, _path) { host == "www.my-domain.com" },
        ]
      }

      it "calls matchers with right parameters" do
        expect(exclude_matchers.first).to receive(:call).once.with("www.my-domain.com", "/my/path")

        subject.ignore?
      end

      it "returns true when the exclude matcher matches" do
        env["HTTP_HOST"] = "www.my-domain.com"
        expect(subject.ignore?).to eq(true)
      end

      it "returns false when the exclude matcher does not match" do
        env["HTTP_HOST"] = "www.other-domain.com"
        expect(subject.ignore?).to eq(false)
      end
    end

    context "with an include matcher" do
      let(:include_matchers) {
        [
          ->(host, _path) { host == "www.my-domain.com" },
        ]
      }

      it "calls matchers with right parameters" do
        expect(include_matchers.first).to receive(:call).once.with("www.my-domain.com", "/my/path")

        subject.ignore?
      end

      it "returns false when the include matcher matches" do
        env["HTTP_HOST"] = "www.my-domain.com"
        expect(subject.ignore?).to eq(false)
      end

      it "returns true when the include matcher does not match" do
        env["HTTP_HOST"] = "www.other-domain.com"
        expect(subject.ignore?).to eq(true)
      end
    end

    context "with two include matchers" do
      let(:include_matchers) {
        [
          ->(host, _path) { host == "www.my-domain.com" },
          ->(_host, path) { path =~ %r{^/my} },
        ]
      }

      it "returns false when the first include matcher matches and the second include matcher matches" do
        env["HTTP_HOST"] = "www.my-domain.com"
        env["PATH_INFO"] = "/my/path"
        expect(subject.ignore?).to eq(false)
      end

      it "returns false when the first include matcher matches and the second include matcher does not match" do
        env["HTTP_HOST"] = "www.my-domain.com"
        env["PATH_INFO"] = "/other/path"
        expect(subject.ignore?).to eq(false)
      end

      it "returns false when the first include matcher does not match and the second include matcher matches" do
        env["HTTP_HOST"] = "www.other-domain.com"
        env["PATH_INFO"] = "/my/path"
        expect(subject.ignore?).to eq(false)
      end

      it "returns true when the first include matcher does not match and the second include matcher does not match" do
        env["HTTP_HOST"] = "www.other-domain.com"
        env["PATH_INFO"] = "/other/path"
        expect(subject.ignore?).to eq(true)
      end
    end

    context "with an exclude matchers and an include matchers" do
      let(:exclude_matchers) {
        [
          ->(host, _path) { host =~ /^admin\./ },
        ]
      }
      let(:include_matchers) {
        [
          ->(host, _path) { host =~ /\.my-domain.com$/ },
        ]
      }

      it "returns true when the exclude matcher matches and the include matcher matches" do
        env["HTTP_HOST"] = "admin.my-domain.com"
        expect(subject.ignore?).to eq(true)
      end

      it "returns true when the exclude matcher matches and the include matcher does not match" do
        env["HTTP_HOST"] = "admin.other-domain.com"
        expect(subject.ignore?).to eq(true)
      end

      it "returns false when the exclude matcher does not match and the include matcher matches" do
        env["HTTP_HOST"] = "www.my-domain.com"
        expect(subject.ignore?).to eq(false)
      end

      it "returns true when the exclude matcher does not match and the include matcher does not match" do
        env["HTTP_HOST"] = "www.other-domain.com"
        expect(subject.ignore?).to eq(true)
      end
    end
  end

  describe "#intercept?" do
    context "with monitoring mode disabled and when request is flagged as coming from a bot" do
      let(:monitoring_mode) { true }

      it "returns false" do
        validation_response = instance_double("Datadome::ValidationResponse", pass: false, redirect: false)
        subject.instance_variable_set('@validation_response', validation_response)

        expect(subject.intercept?).to eq(false)
      end
    end

    context "with monitoring mode enabled and when request is flagged as coming from a bot" do
      let(:monitoring_mode) { true }

      it "returns false" do
        validation_response = instance_double("Datadome::ValidationResponse", pass: false, redirect: false)
        subject.instance_variable_set('@validation_response', validation_response)

        expect(subject.intercept?).to eq(false)
      end
    end
  end
end
