require "./spec_helper"
require "./spec_util"

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
    exec_neph("up_to_date.yml", "up_to_date")
    stdout_of("up_to_date").should eq(date)
  end
end
