require "./spec_helper"

describe "Test" do
  it "should handle simple requests" do
    response = mock_request "GET", "/", ""
    response.status_code.should eq 200
    response.body.should eq "hello"
  end

  it "should handle mounted apis" do
    response = mock_request "GET", "/asd/", ""
    response.status_code.should eq 200
    response.body.should eq "byebye"
  end
end
