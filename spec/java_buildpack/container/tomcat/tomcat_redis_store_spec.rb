# Encoding: utf-8
# Cloud Foundry Java Buildpack
# Copyright 2013 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'spec_helper'
require 'component_helper'
require 'java_buildpack/container/tomcat/tomcat_redis_store'

describe JavaBuildpack::Container::TomcatRedisStore do
  include_context 'component_helper'

  let(:component_id) { 'tomcat' }

  let(:configuration) do
    { 'database'             => 'test-database',
      'timeout'              => 'test-timeout',
      'connection_pool_size' => 'test-connection-pool-size' }
  end

  it 'should not detect without a session-replication service' do
    expect(component.detect).to be_nil
  end

  context do

    before do
      allow(services).to receive(:one_service?).with(/session-replication/, 'hostname', 'port', 'password')
                         .and_return(true)
      allow(services).to receive(:find_service).and_return('credentials' => { 'hostname' => 'test-host',
                                                                              'port'     => 'test-port',
                                                                              'password' => 'test-password' })
    end

    it 'should detect with a session-replication service' do
      expect(component.detect).to eq("tomcat-redis-store=#{version}")
    end

    it 'should copy resources',
       app_fixture:   'container_tomcat_redis_store',
       cache_fixture: 'stub-redis-store.jar' do

      component.compile

      expect(sandbox + "lib/redis_store-#{version}.jar").to exist
    end

    it 'should mutate context.xml',
       app_fixture:   'container_tomcat_redis_store',
       cache_fixture: 'stub-redis-store.jar' do

      component.compile

      expect((sandbox + 'conf/context.xml').read)
      .to eq(Pathname.new('spec/fixtures/container_tomcat_redis_store_context_after.xml').read)
    end

  end

  it 'should do nothing during release' do
    component.release
  end

end
