require 'base'
require 'temp_file_name_generator'
require 'basetaskmocking'

describe BradyW::TempFileNameGenerator do
  after :each do
    rm @should_delete if (@should_delete && File.exists?(@should_delete))
  end

  it 'should generate a valid filename' do
    # arrange
    orig_file = '../dotnetinstaller.xml'

    # act
    @should_delete = BradyW::TempFileNameGenerator.filename orig_file
    puts "Got filename #{@should_delete}, trying to create to ensure it's a valid filename"
    FileUtils.touch @should_delete
  end
end