require "./spec_helper"
require "./spec_util"

neph_install

describe Neph do
  Spec.before_each do
    neph_clean
  end

  it "If no jobs are specified, 'main' job will be executed" do
    exec_neph("main.yml")
    stdout_of("main").should eq("OK\n")
  end

  it "Can define job dependencies" do
    exec_neph("dependencies.yml", "job0")
    stdout_of("job0").should eq("job0\n")
    stdout_of("job1").should eq("job1\n")
    stdout_of("job2").should eq("job2\n")
  end

  it "Can specify job" do
    exec_neph("specify.yml", "specify1")
    stdout_of("specify0").should eq("")
    stdout_of("specify1").should eq("OK\n")
  end

  it "Job is terminated when some error happens in dependencies" do
    exec_neph("error.yml", "err0")
    stdout_of("err0").should eq("")
  end

  it "Ignoring error" do
    exec_neph("ignore_error.yml", "ignore0")
    stdout_of("ignore0").should eq("OK\n")
  end

  it "Can specify sources" do
    exec_neph("up_to_date.yml", "up_to_date")
    date = stdout_of("up_to_date")

    sleep 1

    # The source has not been updated
    exec_neph("up_to_date.yml", "up_to_date")
    stdout_of("up_to_date").should eq(date)

    sleep 1

    # The source has not been updated
    File.touch File.expand_path("../../src/neph.cr", __FILE__)
    exec_neph("up_to_date.yml", "up_to_date")
    stdout_of("up_to_date").should_not eq(date)
  end

  it "Cannot specify same name jobs" do
    exec_neph("same_name_jobs.yml", "same")
    stdout_of("same").should eq("")
  end

  it "Abort job when there is a loop jobs" do
    exec_neph("loop_jobs.yml", "loop0")
    stdout_of("loop0").should eq("")
  end

  it "import feature (Specify single import)" do
    exec_neph("import_single.yml", "import_single")
    stdout_of("import_single").should eq("OK from import_single\n")
    stdout_of("imported_single").should eq("OK from imported_single\n")
  end

  it "import feature (Specify multiple imports)" do
    exec_neph("import.yml", "import_main")
    stdout_of("import_main").should eq("OK from import_main\n")
    stdout_of("import0").should eq("OK from import0\n")
    stdout_of("imported0").should eq("OK from imported0\n")
    stdout_of("imported1").should eq("OK from imported1\n")
  end

  it "Set the stdout result to environment variable" do
    exec_neph("output.yml", "output")
    stdout_of("output").should eq("The result is 4\n\n")
    stdout_of("run_crystal").should eq("4\n")
    stdout_of("just_echo").should eq("I'm echo\n")
    stdout_of("just_echo2").should eq("I'm second echo\n")
  end
end
