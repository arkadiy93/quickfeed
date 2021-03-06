#image/gradle:5.6-jdk12

echo "\n=== Preparing for Test Execution ===\n"

ping -c 4 google.com 2>&1
git config --global url."https://{{ .CreatorAccessToken }}:x-oauth-basic@github.com/".insteadOf "https://github.com/"
ls

git clone  {{ .GetURL }} /home/gradle/user  
git clone  {{ .TestURL }} /home/gradle/test

cat <<EOF> /home/gradle/.gradle/gradle.properties
org.gradle.parallel=true
org.gradle.daemon=true
org.gradle.jvmargs=-Xms256m -Xmx1024m
EOF

# Make sure there are tests in the student repo
rm -rf user/{{ .AssignmentName }}/src/test/*

echo "Removed tests folder on user file\n"

# Generate new Secret.java with new secret value for each run
cd test
cat <<EOF > /home/gradle/test/{{ .AssignmentName }}/src/test/java/common/SecretClass.java
package common;

public class SecretClass {
public static String getSecret() {
  return "{{ .RandomSecret }}";
}
}
EOF



# Fail student code that attempts to access secret
#cd /home/gradle/user/{{ .AssignmentName }}/
#if grep --quiet -r -e common.Secret -e GlobalSecret * ; then
#  echo "\n=== Misbehavior Detected: Failed ===\n"
#  exit
#fi

# Copy tests into student assignments folder for running tests
cp -r /home/gradle/test/{{ .AssignmentName }}/src/test/* /home/gradle/user/{{ .AssignmentName }}/src/test/
echo "copied test files to user folder \n"
echo "/home/gradle/user/{{ .AssignmentName }}/src/test/"
echo `ls /home/gradle/user/{{ .AssignmentName }}/src/test/`

cp /home/gradle/test/{{ .AssignmentName }}/build.gradle /home/gradle/user/{{ .AssignmentName }}/build.gradle
cp /home/gradle/test/{{ .AssignmentName }}/gradlew /home/gradle/user/{{ .AssignmentName }}/gradlew
cd /home/gradle/user/{{ .AssignmentName }}/

# Clear access token and the shell history to avoid leaking information to student test code.
git config --global url."https://0:x-oauth-basic@github.com/".insteadOf "https://github.com/"
history -c

# Perform lab specific setup
if [ -f "setup.sh" ]; then
    bash setup.sh
fi

echo "\n=== Running Tests ===\n"
gradle clean test 2>&1 
echo "\n=== Finished Running Tests ===\n"

