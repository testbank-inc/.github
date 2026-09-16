# 인프라 자원 태그 기준

작성 2026-09-16 · 적용 대상: AWS 계정 972934292912의 전 리전에서 새로 만드는 자원 전체 · 관련 문서: [SECRETS_CONVENTIONS.md](SECRETS_CONVENTIONS.md)

## 1. 목적과 적용 범위

이 문서는 새로 만드는 AWS 자원이 갖춰야 할 태그와 생성 시점의 의무를 정한다. 적용 대상은 AWS 계정 972934292912의 전 리전에서 만드는 모든 자원이며, 만드는 경로(CDK, AWS CLI, 콘솔)를 가리지 않는다.

**통제 대상은 자원 이름 목록이 아니라 태그로 지정한다.** 이름 목록은 만든 시점의 자원만 담고 있어 이후에 생긴 자원이 빠지지만, 태그는 자원을 만들 때 함께 붙으므로 신규 자원이 자동으로 통제 범위에 들어온다.

## 2. 공통 필수 태그

모든 신규 자원에 아래 세 개를 붙인다. 키는 표기한 대소문자 그대로 쓴다.

| 태그 키 | 값 | 설명 |
|---|---|---|
| `Purpose` | 짧은 용도 설명 | 이 자원이 무엇에 쓰이는지 한 줄로. 예: `tb-approval 원본 보호` |
| `ManagedBy` | `cdk` \| `manual-cli` \| `console` | 만든 경로. 값이 `cdk`가 아닌 자원은 코드로 관리되지 않으므로 점검에서 따로 본다. |
| `owner` | 이메일 로컬파트 | 담당자. 예: `wonjin.ko`. 도메인은 붙이지 않는다. |

`Purpose`와 `ManagedBy`는 기존 Lambda 함수의 태그 관행을, `owner`의 소문자 표기는 [SECRETS_CONVENTIONS.md](SECRETS_CONVENTIONS.md)의 시크릿 태그 관행을 그대로 따른 것이다.

## 3. 자원별 태그와 생성 시 의무

### 3.1 AWS Secrets Manager 시크릿

시크릿의 태그는 `rotation-class`·`rotation-days`·`owner`·`consumer-mode`·`rotated-on` 다섯 개이며, 정의와 값 형식은 [SECRETS_CONVENTIONS.md](SECRETS_CONVENTIONS.md) 2절·5절에 있다. 이 문서는 그 기준을 그대로 따르고 여기서 다시 서술하지 않는다. 시크릿 생성 명령도 같은 문서를 따른다.

### 3.2 RDS 수동 스냅샷 · EBS 수동 스냅샷

자동 백업이 아니라 사람이 만드는 수동 스냅샷이 대상이다. 대상에는 DB 인스턴스 스냅샷, DB 클러스터 스냅샷, EBS 볼륨 스냅샷이 모두 들어간다.

| 태그 키 | 값 | 설명 |
|---|---|---|
| `expire-after` | `YYYY-MM-DD` | 보관 기한. 기본값은 생성일 + 30일. 근거를 `Purpose`에 적으면 최대 생성일 + 90일까지 둘 수 있다. |
| `Purpose` | 짧은 용도 설명 | 왜 이 스냅샷을 남기는지. 기한을 30일보다 길게 잡았다면 그 근거도 여기에 적는다. |
| `owner` | 이메일 로컬파트 | 담당자 |

**미암호화 스냅샷은 만들지 않는다.** 원본 볼륨이나 DB 인스턴스가 미암호화라 스냅샷도 미암호화로 만들어졌다면, `copy-db-snapshot`(RDS) 또는 `copy-snapshot`(EBS)으로 KMS 키를 지정한 암호화본을 만들고 미암호화 원본 스냅샷은 즉시 삭제한다.

기한이 지난 스냅샷은 일일 가드 Lambda가 통보한다. 삭제는 자동으로 하지 않으며, 담당자가 필요 여부를 확인한 뒤 직접 실행한다.

```bash
# RDS DB 인스턴스 수동 스냅샷
aws rds create-db-snapshot --region ap-northeast-2 \
  --db-instance-identifier <db-instance-id> \
  --db-snapshot-identifier <snapshot-id> \
  --tags Key=expire-after,Value=<YYYY-MM-DD> \
         Key=Purpose,Value='<용도>' \
         Key=owner,Value=<owner>

# 원본이 미암호화여서 스냅샷도 미암호화인 경우: 암호화본을 만들고 원본을 삭제
aws rds copy-db-snapshot --region ap-northeast-2 \
  --source-db-snapshot-identifier <snapshot-id> \
  --target-db-snapshot-identifier <snapshot-id>-encrypted \
  --kms-key-id alias/aws/rds --copy-tags
aws rds delete-db-snapshot --region ap-northeast-2 \
  --db-snapshot-identifier <snapshot-id>

# EBS 볼륨 수동 스냅샷
aws ec2 create-snapshot --region ap-northeast-2 \
  --volume-id <volume-id> --description '<용도>' \
  --tag-specifications 'ResourceType=snapshot,Tags=[{Key=expire-after,Value=<YYYY-MM-DD>},{Key=Purpose,Value=<용도>},{Key=owner,Value=<owner>}]'
```

### 3.3 Amazon S3 버킷

| 태그 키 | 값 | 설명 |
|---|---|---|
| `log-class` | `audit` \| `none` | `audit`는 감사 로그·액세스 로그 버킷, `none`은 그 밖의 버킷 |

`log-class=audit`는 bastion 접속 기록, AWS CloudTrail, 로드 밸런서 액세스 로그, AWS WAF 로그, Amazon CloudFront 액세스 로그를 담는 버킷에 붙인다. 이 값을 붙인 버킷에는 다음 두 가지가 의무다.

1. **삭제 방지 버킷 정책.** 버킷 정책으로 `s3:DeleteObject`·`s3:DeleteObjectVersion`을 거부해 적재된 로그가 지워지지 않게 한다.
2. **365일 이상 보존.** 수명 주기 규칙의 만료 기간을 365일 미만으로 두지 않는다.

버킷 생성 명령에는 태그 인자가 없다. 따라서 `create-bucket` 직후 같은 명령 줄에서 `put-bucket-tagging`을 이어 실행해, 태그가 빠진 버킷이 남지 않게 한다. 공통 필수 태그도 이때 함께 넣는다.

```bash
aws s3api create-bucket --region ap-northeast-2 --bucket <bucket-name> \
  --create-bucket-configuration LocationConstraint=ap-northeast-2 && \
aws s3api put-bucket-tagging --bucket <bucket-name> --tagging \
  'TagSet=[{Key=log-class,Value=audit},{Key=Purpose,Value=<용도>},{Key=ManagedBy,Value=manual-cli},{Key=owner,Value=<owner>}]'
```

### 3.4 AWS WAF 웹 ACL

웹 ACL에는 태그 의무가 없다. 대신 **생성 직후 같은 명령 줄에서 `put-logging-configuration`을 실행해 로깅을 붙인다.** 웹 ACL은 만든 다음 로깅을 따로 붙이는 절차가 잊히기 쉬워, 로깅 없는 웹 ACL이 운영에 남는 일이 반복됐다.

로그 목적지와 설정은 기존 로드 밸런서용 웹 ACL 표준과 동일하게 맞춘다.

- 목적지: `aws-waf-logs-`로 시작하는 이름의 S3 버킷(이 접두사는 AWS WAF의 요구사항이다). 그 버킷은 3.3의 `log-class=audit` 대상이다.
- 기록 범위: 매칭된 요청만 남긴다(`DefaultBehavior=DROP` + BLOCK·COUNT 동작 KEEP).
- 마스킹: `authorization`·`cookie` 등 민감 헤더는 `RedactedFields`로 가린다.
- 보존: 365일 이상.

```bash
ACL_ARN=$(aws wafv2 create-web-acl --region ap-northeast-2 --scope REGIONAL \
  --name <web-acl-name> --default-action Allow={} \
  --visibility-config SampledRequestsEnabled=true,CloudWatchMetricsEnabled=true,MetricName=<metric-name> \
  --rules file://<rules.json> --query 'Summary.ARN' --output text) && \
aws wafv2 put-logging-configuration --region ap-northeast-2 --logging-configuration \
  "ResourceArn=$ACL_ARN,\
LogDestinationConfigs=[arn:aws:s3:::aws-waf-logs-<bucket-suffix>],\
LoggingFilter={DefaultBehavior=DROP,Filters=[{Behavior=KEEP,Requirement=MEETS_ANY,Conditions=[{ActionCondition={Action=BLOCK}},{ActionCondition={Action=COUNT}}]}]},\
RedactedFields=[{SingleHeader={Name=authorization}},{SingleHeader={Name=cookie}}]"
```

CloudFront 배포에 붙이는 웹 ACL은 `--scope CLOUDFRONT`이며 `--region us-east-1`에서 만든다. 로깅을 붙이는 절차는 같다.

### 3.5 보안 그룹

자원을 만들 때 보안 그룹을 반드시 명시하고, **default 보안 그룹은 참조하지 않는다.** 계정의 default 보안 그룹은 전 리전에서 규칙 0/0으로 잠그고 `DO-NOT-USE` 태그를 붙여 두었다. 보안 그룹을 지정하지 않으면 AWS가 default 보안 그룹을 붙이므로, 자원 생성 명령에 `--security-group-ids`(또는 이에 해당하는 인자)를 항상 넣는다.

## 4. 강제 장치

세 층으로 나눈다.

1. **생성 시점 차단 — tb-ops 플러그인의 PreToolUse 훅.** Claude Code 세션에서 3절의 생성 명령을 실행하려 하면 훅이 태그와 로깅 인자를 검사하고, 조건을 채우지 못하면 실행을 막는다. 적용 범위는 Claude Code 세션을 거치는 AWS CLI 경로뿐이며, CDK 배포와 콘솔 작업에는 적용되지 않는다.
2. **사후 검사 — 일일 가드 Lambda `isms-resource-guard`.** 만들어진 경로와 무관하게 자원의 실제 상태를 매일 검사해 통보한다. 검사 항목은 공통 필수 태그 누락, 기한이 지난 스냅샷, 미암호화 스냅샷, `log-class=audit` 버킷의 삭제 방지 정책·보존 기간, 로깅이 없는 웹 ACL이다. 가드는 통보만 하고 자원을 지우거나 고치지 않는다.
3. **판단 기준 — 이 문서와 tb-ops 스킬.** 훅과 가드가 무엇을 통과시키고 무엇을 막을지는 이 문서를 기준으로 한다. 기준을 바꿀 때는 이 문서를 먼저 고치고 훅·가드를 맞춘다.

훅에 막혔다면 우회하지 말고 이 문서의 해당 절을 읽어 태그와 로깅을 갖춘 뒤 같은 명령을 다시 실행한다. 기준을 적용할 수 없는 사정이 있으면 사유를 확인받고 나서 진행한다.

## 5. 개정 이력

| 날짜 | 내용 |
|---|---|
| 2026-09-16 | 제정. 공통 필수 태그 3종, 자원별 태그와 생성 시 의무(시크릿·스냅샷·S3 버킷·웹 ACL·보안 그룹), 강제 장치 3층 |
