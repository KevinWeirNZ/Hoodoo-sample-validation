require 'spec_helper'
require_relative '../validate_service.rb'
require 'json_spec' # Require Gem file for testing JSON..?
require 'json' #require for use of .to_json ..?

# Create ValidateService for testing purposes comprised of the interface we are testing.
class ValidateService < Hoodoo::Services::Service
  comprised_of ValidateInterface
end

describe "validate service" do
  include Rack::Test::Methods
  # Create rack builder object for the test.
  context "get /1/Hello" do
    let(:app) {
      Rack::Builder.new do
        use( Hoodoo::Services::Middleware )
        run( ValidateService.new )
      end
    }

    it "returns http status code == 200, when the payload is valid" do
      post 'v1/Hello',
      { 'first_name' => 'John' , 'surname' => 'Smith' }.to_json,
      { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      expect( last_response.status ).to eq 200
    end

    it "returns http status code 422, when the payload has not been sent in a format that is recognised by the service schema" do
      post 'v1/Hello',
      { 'first_name' => 'John' }.to_json,
      { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      # Expect the status to return 422 'Unprocessable Entity'(platform.malformed) because the payload has not been sent in a format that is recognised by the service schema.
      expect( last_response.status ).to eq 422
    end

    it "returns a correct response body, when passed a valid request" do
      post 'v1/Hello',
      { 'first_name' => 'John' , 'surname' => 'Smith'}.to_json,
      { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      # Create a 'message' json variable to compare with the body of the response.
      message = { 'message' => "Hello John Smith"}.to_json
      expect( last_response.body ).to be_json_eql(message)
    end

    it "returns an error that includes a code, message and reference when passed an invalid request" do
      post 'v1/Hello',
      { 'first_name' => 'John'}.to_json,
      { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      error_response = {
        "errors": [
          {
            "code": "generic.required_field_missing",
            "message": "Field `surname` is required",
            "reference": "surname"
          }
        ],
        "kind": "Errors"}.to_json
      expect( last_response.body ).to be_json_eql(error_response).excluding("interaction_id")
    end

  end
end
