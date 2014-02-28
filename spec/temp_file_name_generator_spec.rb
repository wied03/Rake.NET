require 'base'

describe BradyW::TempFileNameGenerator do
  after :each do
    rm @should_delete if (@should_delete && File.exists?(@should_delete))
  end

  it 'should generate a valid filename' do
    # arrange
    orig_file = '../dotnetinstaller.xml'

    # act
    @should_delete = BradyW::TempFileNameGenerator.from_existing_file orig_file
    puts "Got filename #{@should_delete}, trying to create to ensure it's a valid filename"
    FileUtils.touch @should_delete
  end

  it 'should work OK with a random filename (not from an existing file)' do
    # arrange

    # act
    @should_delete = BradyW::TempFileNameGenerator.random_filename 'theprefix', '.txt'

    # assert
    /theprefix_\d+\.txt/.should match @should_delete
  end
end