namespace do
  bacon = resource "service", "bacon"
  user "#{namespace}-alice"
  user "#{namespace}-bob" do
    can "fry", bacon
  end
end
