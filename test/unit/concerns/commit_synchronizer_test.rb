require "test_helper"
require "support/houston/adapters/version_control/mock_adapter"


class CommitSynchronizerTest < ActiveSupport::TestCase
  attr_reader :project, :commit, :unreachable_commit, :reachable_commit
  delegate :repo, to: :project
  
  setup do
    @project = Project.create!(name: "Test", slug: "test", version_control_name: "Mock")
  end
  
  
  context "#sync!" do
    should "make sure that the local repo is up-to-date" do
      mock(repo).refresh!
      project.commits.sync!
    end
    
    context "when there new commits, it" do
      setup do
        mock(repo).all_commits.returns %w{aaaaaaaa}
        mock(repo).native_commit("aaaaaaaa").returns native_commit(sha: "aaaaaaaa")
      end
      
      should "create records for them" do
        project.commits.sync!
        assert_equal %w{aaaaaaaa}, project.commits.pluck(:sha),
          "Expected a commit to have been created with the new sha"
      end
    end
    
    context "when there are unreachable commits, it" do
      setup do
        @unreachable_commit = project.commits.create!(params(sha: "00000001"))
        @reachable_commit = project.commits.create!(params(sha: "00000002"))
        mock(repo).all_commits.returns [reachable_commit.sha]
      end
      
      should "mark them" do
        project.commits.sync!
        assert unreachable_commit.reload.unreachable?,
          "Expected the unreachable commit to have been flagged so"
      end
    end
  end
  
  
  context "#find_or_create_by_sha!" do
    context "when a commit exists locally with the given sha" do
      setup do
        @commit = project.commits.create!(params)
      end
      
      should "find the commit by the full sha" do
        assert_equal commit, project.find_commit_by_sha(commit.sha)
      end
      
      should "find the commit by the partial sha" do
        assert_equal commit, project.find_commit_by_sha(commit.sha[0...8])
      end
    end
    
    context "when the repo contains an unsycned commit with the given sha" do
      setup do
        mock(repo).native_commit("aaaaaaaa").returns native_commit(sha: "aaaaaaaa")
      end
      
      should "find and synchronize the commit" do
        assert_difference "project.commits.count", +1, "Expected a commit to have been created" do
          assert project.find_commit_by_sha("aaaaaaaa"), "Expected to find a commit"
        end
      end
    end
    
    context "when the repo does not even contain a commit with that sha" do
      setup do
        mock(repo).native_commit(anything) do
          raise Houston::Adapters::VersionControl::CommitNotFound
        end
      end
      
      should "return nil" do
        assert_equal nil, project.find_commit_by_sha("aaaaaaaa")
      end
    end
  end
  
  
private
  
  def params(overrides={})
    overrides.reverse_merge({
      project: project,
      sha: SecureRandom.hex(16),
      message: "nothing to see here",
      authored_at: Time.now,
      committer: "Houston",
      committer_email: "commitbot@houston.com"
    })
  end
  
  def native_commit(overrides={})
    OpenStruct.new(overrides.reverse_merge({
      sha: SecureRandom.hex(16),
      message: "nothing to see here",
      authored_at: Time.now,
      author_name: "Houston",
      author_email: "commitbot@houston.com"
    }))
  end
  
end
