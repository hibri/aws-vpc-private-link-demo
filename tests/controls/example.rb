# encoding: utf-8
# copyright: 2018, The Authors

title 'sample section'


describe aws_vpc  do
  it {should exist}
  its ('instance_tenancy')  {should eq 'default'}
  its ('state') {should eq 'available'}
end
