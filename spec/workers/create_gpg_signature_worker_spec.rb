require 'spec_helper'

describe CreateGpgSignatureWorker do
  let(:project) { create(:project, :repository) }

  context 'when GpgKey is found' do
    let(:commit_sha) { '0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33' }

    it 'calls Gitlab::Gpg::Commit#signature' do
      expect(Gitlab::Gpg::Commit).to receive(:new).with(project, commit_sha).and_call_original

      expect_any_instance_of(Gitlab::Gpg::Commit).to receive(:signature)

      described_class.new.perform(commit_sha, project.id)
    end
  end

  context 'when Commit is not found' do
    let(:nonexisting_commit_sha) { '0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a34' }

    it 'does not raise errors' do
      expect { described_class.new.perform(nonexisting_commit_sha, project.id) }.not_to raise_error
    end
  end

  context 'when Project is not found' do
    let(:nonexisting_project_id) { -1 }

    it 'does not raise errors' do
      expect { described_class.new.perform(anything, nonexisting_project_id) }.not_to raise_error
    end

    it 'does not call Gitlab::Gpg::Commit#signature' do
      expect_any_instance_of(Gitlab::Gpg::Commit).not_to receive(:signature)

      described_class.new.perform(anything, nonexisting_project_id)
    end
  end

  it_behaves_like 'sidekiq worker'
end
