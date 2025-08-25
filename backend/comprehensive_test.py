#!/usr/bin/env python3
"""
SimLog API 종합 테스트 스크립트
"""

import requests
import json
import time

# Railway 백엔드 URL
BASE_URL = "https://simlog-production.up.railway.app"

def create_developer_account():
    """개발자 계정 생성 (테스트용)"""
    print("\n=== 0. 개발자 계정 생성 ===")
    
    developer_data = {
        "email": "developer@simlog.com",
        "password": "developer123",
        "nickname": "개발자"
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/auth/signup",
            json=developer_data,
            headers={"Content-Type": "application/json"}
        )
        
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text}")
        
        if response.status_code == 200:
            print("✅ 개발자 계정 생성 성공!")
            return True
        elif response.status_code == 400 and "이미 사용 중인" in response.text:
            print("ℹ️ 개발자 계정이 이미 존재합니다.")
            return True
        else:
            print("❌ 개발자 계정 생성 실패")
            return False
            
    except Exception as e:
        print(f"❌ 오류: {e}")
        return False

def test_health():
    """기본 헬스체크 테스트"""
    print("=== 1. 헬스체크 테스트 ===")
    try:
        response = requests.get(f"{BASE_URL}/health")
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text}")
        if response.status_code == 200:
            print("✅ 헬스체크 성공!")
            return True
        else:
            print("❌ 헬스체크 실패")
            return False
    except Exception as e:
        print(f"❌ 오류: {e}")
        return False

def test_signup():
    """회원가입 테스트"""
    print("\n=== 2. 회원가입 테스트 ===")
    
    # 고유한 타임스탬프 기반 테스트 데이터
    timestamp = int(time.time())
    test_users = [
        {
            "email": f"test{timestamp}@example.com",
            "password": "testpassword123",
            "nickname": f"테스트사용자{timestamp}"
        },
        {
            "email": f"test{timestamp+1}@example.com",
            "password": "123456",
            "nickname": f"테스트{timestamp+1}"
        }
    ]
    
    success_count = 0
    for i, user_data in enumerate(test_users, 1):
        print(f"\n--- 테스트 사용자 {i} ---")
        try:
            response = requests.post(
                f"{BASE_URL}/auth/signup",
                json=user_data,
                headers={"Content-Type": "application/json"}
            )
            
            print(f"Status: {response.status_code}")
            print(f"Response: {response.text}")
            
            if response.status_code == 200:
                print("✅ 회원가입 성공!")
                success_count += 1
                # 성공한 사용자 정보 저장
                user_data['response'] = response.json()
            elif response.status_code == 422:
                print("⚠️ 데이터 검증 실패")
                try:
                    error_data = response.json()
                    print(f"오류 상세: {json.dumps(error_data, indent=2, ensure_ascii=False)}")
                except:
                    pass
            else:
                print("❌ 예상치 못한 오류")
                
        except Exception as e:
            print(f"❌ 오류: {e}")
    
    print(f"\n📊 회원가입 성공: {success_count}/{len(test_users)}")
    return success_count > 0

def test_login():
    """로그인 테스트"""
    print("\n=== 3. 로그인 테스트 ===")
    
    test_credentials = [
        {
            "email": "developer@simlog.com",
            "password": "developer123"
        }
    ]
    
    success_count = 0
    access_tokens = []
    
    for i, creds in enumerate(test_credentials, 1):
        print(f"\n--- 로그인 테스트 {i} ---")
        try:
            response = requests.post(
                f"{BASE_URL}/auth/login",
                json=creds,
                headers={"Content-Type": "application/json"}
            )
            
            print(f"Status: {response.status_code}")
            print(f"Response: {response.text}")
            
            if response.status_code == 200:
                print("✅ 로그인 성공!")
                success_count += 1
                login_data = response.json()
                if 'access_token' in login_data:
                    access_tokens.append(login_data['access_token'])
                    print("🔑 액세스 토큰 획득!")
            elif response.status_code == 422:
                print("⚠️ 데이터 검증 실패")
            else:
                print("❌ 로그인 실패")
                
        except Exception as e:
            print(f"❌ 오류: {e}")
    
    print(f"\n📊 로그인 성공: {success_count}/{len(test_credentials)}")
    return access_tokens

def test_protected_endpoints(access_tokens):
    """보호된 엔드포인트 테스트"""
    if not access_tokens:
        print("\n⚠️ 액세스 토큰이 없어 보호된 엔드포인트 테스트를 건너뜁니다.")
        return
    
    print("\n=== 4. 보호된 엔드포인트 테스트 ===")
    
    token = access_tokens[0]
    headers = {"Authorization": f"Bearer {token}"}
    
    # 사용자 정보 조회
    print("\n--- 사용자 정보 조회 ---")
    try:
        response = requests.get(f"{BASE_URL}/users/me", headers=headers)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            print("✅ 사용자 정보 조회 성공!")
        else:
            print(f"❌ 실패: {response.text}")
    except Exception as e:
        print(f"❌ 오류: {e}")
    
    # 정원 정보 조회
    print("\n--- 정원 정보 조회 ---")
    try:
        response = requests.get(f"{BASE_URL}/garden/info", headers=headers)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            print("✅ 정원 정보 조회 성공!")
        else:
            print(f"❌ 실패: {response.text}")
    except Exception as e:
        print(f"❌ 오류: {e}")

def test_error_handling():
    """오류 처리 테스트"""
    print("\n=== 5. 오류 처리 테스트 ===")
    
    # 잘못된 데이터로 회원가입 시도
    print("\n--- 잘못된 데이터 테스트 ---")
    invalid_data = {
        "email": "invalid-email",
        "password": "123",
        "nickname": ""
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/auth/signup",
            json=invalid_data,
            headers={"Content-Type": "application/json"}
        )
        
        print(f"Status: {response.status_code}")
        if response.status_code == 422:
            print("✅ 데이터 검증 정상 작동!")
            try:
                error_data = response.json()
                print(f"오류 상세: {json.dumps(error_data, indent=2, ensure_ascii=False)}")
            except:
                pass
        else:
            print(f"⚠️ 예상과 다른 응답: {response.text}")
            
    except Exception as e:
        print(f"❌ 오류: {e}")

def main():
    """메인 테스트 실행"""
    print("🚀 SimLog API 종합 테스트 시작!")
    print(f"Base URL: {BASE_URL}")
    print("=" * 50)
    
    # 0. 개발자 계정 생성
    create_developer_account()
    
    # 1. 헬스체크
    if not test_health():
        print("❌ 헬스체크 실패로 테스트 중단")
        return
    
    # 2. 회원가입
    signup_success = test_signup()
    
    # 3. 로그인
    access_tokens = test_login()
    
    # 4. 보호된 엔드포인트
    test_protected_endpoints(access_tokens)
    
    # 5. 오류 처리
    test_error_handling()
    
    print("\n" + "=" * 50)
    print("🏁 종합 테스트 완료!")
    
    if signup_success and access_tokens:
        print("🎉 SimLog API가 정상적으로 동작하고 있습니다!")
    else:
        print("⚠️ 일부 기능에 문제가 있을 수 있습니다.")

if __name__ == "__main__":
    main()
